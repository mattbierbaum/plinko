import vector
import objects
import forces
import observers
import neighborlist
import simulation
import image
import plotting

import std/json
import std/math
import std/tables

type ObjectTranslationGenerator = proc(pos: Vec): Circle
type ObjectScaleGenerator = proc(scale: float): MaskedCircle

proc hex_grid_object*(rows: int, cols: int, f: ObjectTranslationGenerator): (seq[Circle], Vec) =
    var a = 1.0
    var rt3 = math.sqrt(3.0)

    var objs: seq[Circle] = @[]
    for i in 0 .. rows-1:
        for j in 0 .. cols-1:
            if (i.float*a*rt3 >= 1e-10):
                objs.add(f([j.float*a, i.float*a*rt3]))

            if not (j == cols - 1):
                objs.add(f([(j.float+0.5)*a, (i.float+0.5)*a*rt3]))

    let boundary = [(cols.float-1.0)*a, (rows.float+1)*rt3*a]
    return (objs, boundary)

proc concentric*(min_scale: float, max_scale: float, steps: int, f: ObjectScaleGenerator): (seq[MaskedCircle], Box) =
    var objs: seq[MaskedCircle] = @[]
    var boundary: Box
    for i in 0 .. steps - 1:
        let s = min_scale + (max_scale - min_scale) / (steps.float-1.0) * i.float
        let obj = f(s)
        let bd = obj.boundary()

        if boundary == nil:
            boundary = bd
        else:
            boundary = Box().initBox(ll=min(boundary.ll, bd.ll), uu=max(boundary.uu, bd.uu))

        objs.add(obj)
    return (objs, boundary)

proc square_grid_object*(rows: int, cols: int, f: ObjectTranslationGenerator): (seq[Object], Vec) =
    var a = 1.0
    
    var objs: seq[Object] = @[]
    for i in 1 .. rows+2:
        for j in 1 .. cols+2:
            objs.add(f([a*(j.float-1.0), a*(i.float-1.0)]))

    let boundary = [(cols.float+1.0)*a, (rows.float+1.0)*a]
    return (objs, boundary)

proc json_to_vec(json: JsonNode): Vec =
    var vals: seq[float] = @[]
    for elem in json.elems:
        vals.add(elem.getFloat())
    return [vals[0], vals[1]]

proc json_to_ivec(json: JsonNode): array[2, int] =
    var vals: seq[int] = @[]
    for elem in json.elems:
        vals.add(elem.getInt())
    return [vals[0], vals[1]]

proc json_to_box(node: JsonNode, sim: Simulation): Box =
    let ll = json_to_vec(node{"ll"})
    let uu = json_to_vec(node{"uu"})
    let damp = node{"damp"}.getFloat(1.0)
    let name = node{"name"}.getStr("")
    return Box().initBox(ll=ll, uu=uu, damp=damp, name=name)

proc json_to_circle(node: JsonNode, sim: Simulation): Circle =
    let pos = json_to_vec(node{"pos"})
    let rad = node{"rad"}.getFloat()
    let damp = node{"damp"}.getFloat()
    let name = node{"name"}.getStr("")
    return Circle().initCircle(pos=pos, rad=rad, damp=damp, name=name)

proc json_to_masked_circle(node: JsonNode, sim: Simulation): MaskedCircle =
    let pos = json_to_vec(node{"pos"})
    let rad = node{"rad"}.getFloat()
    let damp = node{"damp"}.getFloat()
    let name = node{"name"}.getStr("")

    let f = node{"mask"}
    let n = f{"n"}.getInt(0)
    let gap = f{"gap"}.getFloat(0.0)
    let offset = f{"offset"}.getFloat(0.0)
    let mask = circle_nholes(nholes=n, eps=gap, offset=offset)

    return MaskedCircle().initMaskedCircle(pos=pos, rad=rad, damp=damp, name=name, mask=mask)

proc json_to_object(node: JsonNode, sim: Simulation): seq[Object] =
    var objs: seq[Object] = @[]
    if node{"type"}.getStr() == "circle":
        objs.add(json_to_circle(node, sim))

    if node{"type"}.getStr() == "masked_circle":
        objs.add(json_to_masked_circle(node, sim))

    if node{"type"}.getStr() == "box":
        objs.add(json_to_box(node, sim))

    if node{"type"}.getStr() == "ref":
        if node{"index"} != nil:
            let index = node{"index"}.getInt()
            objs.add(sim.objects[index])
        if node{"name"} != nil:
            let name = node{"name"}.getStr()
            objs.add(sim.object_by_name(name))

    if node{"type"}.getStr() == "tri-lattice":
        proc generate_object(pos: Vec): Circle =
            var o: Circle = json_to_circle(node{"object"}, sim)
            o = o.translate(-o.center()).Circle
            o = o.translate(pos).Circle
            return o

        let rows = node{"rows"}.getInt(0)
        let cols = node{"columns"}.getInt(0)
        let (obj, boundary) = hex_grid_object(rows=rows, cols=cols, f=generate_object)
        objs.add(Box().initBox(ll=[0.0,0.0], uu=boundary, name="boundary"))
        for o in obj:
            objs.add(o)

    if node{"type"}.getStr() == "concentric":
        proc generate_object(scale: float): MaskedCircle =
            var o: MaskedCircle = json_to_masked_circle(node{"object"}, sim)
            o = o.scale(scale).MaskedCircle
            return o

        let min_scale = node{"scaling_function"}{"min_scale"}.getFloat(1.0)
        let max_scale = node{"scaling_function"}{"max_scale"}.getFloat(1.0)
        let steps = node{"scaling_function"}{"steps"}.getInt(1)
        let (obj, boundary) = concentric(min_scale=min_scale, max_scale=max_scale, steps=steps, f=generate_object)
        boundary.name = "boundary"
        objs.add(boundary)
        for o in obj:
            objs.add(o)

    return objs

proc json_to_particle(node: JsonNode, sim: Simulation): ParticleGroup =
    if node{"type"}.getStr() == "single":
        let pos = json_to_vec(node{"pos"})
        let vel = json_to_vec(node{"vel"})
        let p = PointParticle().initPointParticle(pos=pos, vel=vel)
        return SingleParticle().initSingleParticle(p)

proc json_to_observer(node: JsonNode, sim: Simulation): Observer =
    if node{"type"}.getStr() == "time":
        let interval = node{"interval"}.getFloat()
        return TimePrinter().initTimePrinter(interval)

    if node{"type"}.getStr() == "step":
        let interval = node{"interval"}.getInt()
        return StepPrinter().initStepPrinter(interval)

    elif node{"type"}.getStr() == "svg":
        let filename = node{"filename"}.getStr()
        let box = cast[Box](json_to_object(node{"box"}, sim)[0])
        let resolution = node{"resolution"}.getInt()
        let dpi = max(box.uu[0] - box.ll[0], box.uu[1] - box.ll[1]) / resolution.float / 100.0
        return SVGLinePlot().initSVGLinePlot(filename=filename, box=box, lw=dpi)

    elif node{"type"}.getStr() == "pgm":
        let eqhist: NormFunction = proc(data: seq[float]): seq[float] =
            return image.eq_hist(data, nbins=256*256)

        let cmap_table = {"gray": gray, "gray_r": gray_r}.toTable()
        let norm_table = {"eq_hist": eqhist}.toTable()
        let blend_table = {
            "add": blendmode_additive,
            "min": blendmode_min,
            "max": blendmode_max,
            "avg": blendmode_average,
        }.toTable()

        let filename: string = node{"filename"}.getStr()
        let format: string = node{"format"}.getStr("pgm2")
        let cmap = cmap_table[node{"cmap"}.getStr("gray_r")]
        let norm = norm_table[node{"norm"}.getStr("eq_hist")]
        let blend = blend_table[node{"blend"}.getStr("add")]

        let box = cast[Box](json_to_object(node{"box"}, sim)[0])
        let resolution = node{"resolution"}.getInt()
        let dpi = resolution.float / max(box.uu[0] - box.ll[0], box.uu[1] - box.ll[1]) 

        let plotter = DensityPlot().initDensityPlot(box=box, dpi=dpi, blendmode=blend)
        let obs = ImageRecorder().initImageRecorder(
            filename=filename, plotter=plotter, format=format,
            cmap=cmap, norm=norm)
        return obs

proc json_to_neighborlist(node: JsonNode, sim: Simulation): Neighborlist =
    if node{"type"}.getStr() == "naive":
        return Neighborlist()
    if node{"type"}.getStr() == "cell":
        let box = cast[Box](json_to_object(node{"box"}, sim)[0])
        let ncells = json_to_ivec(node{"ncells"})
        let buffer = node{"buffer"}.getFloat()
        return CellNeighborlist().initCellNeighborlist(box=box, ncells=ncells, buffer=buffer)

proc json_to_force(node: JsonNode, sim: Simulation): IndependentForce =
    if node{"type"}.getStr() == "gravity":
        return generate_force_gravity(node{"g"}.getFloat())

proc json_to_simulation*(json: string): Simulation =
    var sim = Simulation().initSimulation()

    var cfg = parseJson(json)
    if cfg{"simulation"} != nil:
        var s = cfg["simulation"]
        sim.eps = s{"eps"}.getFloat(1e-6)
        sim.dt = s{"dt"}.getFloat(1e-2)
        sim.max_steps = s{"max_steps"}.getInt(1)
        sim.verbose = s{"verbose"}.getBool(true)
        sim.linear = s{"linear"}.getBool(true)
        sim.equal_time = s{"equal_time"}.getBool(false)
        sim.accuracy_mode = s{"accuracy"}.getBool(false)

    if cfg{"objects"} != nil:
        for node in cfg{"objects"}:
            for obj in json_to_object(node, sim):
                sim.add_object(obj)

    if cfg{"particles"} != nil:
        for node in cfg{"particles"}:
            sim.add_particle(json_to_particle(node, sim))

    if cfg{"observers"} != nil:
        for node in cfg{"observers"}:
            sim.add_observer(json_to_observer(node, sim))

    if cfg{"forces"} != nil:
        for node in cfg{"forces"}:
            sim.add_force(json_to_force(node, sim))

    # This must be last in the list.
    if cfg{"neighborlist"} != nil:
        sim.set_neighborlist(json_to_neighborlist(cfg{"neighborlist"}, sim))
    else:
        sim.set_neighborlist(Neighborlist())

    sim.initialize()
    return sim