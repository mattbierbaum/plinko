import forces
import image
import interrupts
import neighborlist
import objects
import observers
import plotting
import simulation
import vector

import std/json
import std/math
import std/tables

proc GenericImageRecorder(): ImageRecorder = return ImageRecorder()
proc GenericPeriodicImageRecorder(): PeriodicImageRecorder = return PeriodicImageRecorder()
proc GenericSVGLinePlot(): SVGLinePlot = return SVGLinePlot()
var ImageRecorderImpl = GenericImageRecorder
var PeriodicImageRecorderImpl = GenericPeriodicImageRecorder
var SVGLinePlotImpl = GenericSVGLinePlot

when not defined(js):
    import observers_native
    ImageRecorderImpl = proc(): ImageRecorder = return NativeImageRecorder()
    PeriodicImageRecorderImpl = proc(): PeriodicImageRecorder = return NativePeriodicImageRecorder()
    SVGLinePlotImpl = proc(): SVGLinePlot = return NativeSVGLinePlot()
else:
    import observers_js
    ImageRecorderImpl = proc(): ImageRecorder = return JsImageRecorder()
    SVGLinePlotImpl = proc(): SVGLinePlot = return JsSvgLinePlot()

type ObjectTranslationGenerator[T] = proc(pos: Vec): T
type ObjectScaleGenerator[T] = proc(scale: float): T

proc hex_grid_object*[T](rows: int, cols: int, top: float, f: ObjectTranslationGenerator[T]): (seq[T], Box) =
    var a = 1.0
    var rt3 = math.sqrt(3.0)

    var objs: seq[T] = @[]
    for i in 0 .. rows-1:
        for j in 0 .. cols-1:
            if (i.float*a*rt3 >= 1e-10):
                objs.add(f([j.float*a, i.float*a*rt3]))

            if not (j == cols - 1):
                objs.add(f([(j.float+0.5)*a, (i.float+0.5)*a*rt3]))

    let boundary = [(cols.float-1.0)*a, (rows.float)*rt3*a]
    let box = Box().initBox(ll=[0.0,0.0], uu=boundary+[0.0, top], name="boundary")
    box.top.name = "top"
    box.bottom.name = "bottom"
    return (objs, box)

proc concentric*[T](min_scale: float, max_scale: float, steps: int, f: ObjectScaleGenerator[T]): (seq[T], Box) =
    var objs: seq[T] = @[]
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
    boundary.top.name = "top"
    boundary.bottom.name = "bottom"
    boundary.name = "boundary"
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
    if json == nil:
        return [0.0, 0.0]
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

proc json_to_segment(node: JsonNode, sim: Simulation): Segment =
    let p0 = json_to_vec(node{"p0"})
    let p1 = json_to_vec(node{"p1"})
    let damp = node{"damp"}.getFloat(1.0)
    let name = node{"name"}.getStr("")
    return Segment().initSegment(p0=p0, p1=p1, damp=damp, name=name)

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

    if node{"type"}.getStr() == "segment":
        objs.add(json_to_segment(node, sim))

    if node{"type"}.getStr() == "ref":
        if node{"index"} != nil:
            let index = node{"index"}.getInt()
            objs.add(sim.objects[index])
        if node{"name"} != nil:
            let name = node{"name"}.getStr()
            objs.add(sim.object_by_name(name))

    if node{"type"}.getStr() == "tri-lattice":
        proc generate_object_translate(pos: Vec): Object =
            var o: Object = json_to_object(node{"object"}, sim)[0]
            o = o.translate(-o.center())
            o = o.translate(pos)
            return o

        let top = node{"top"}.getFloat(0.0)
        let rows = node{"rows"}.getInt(0)
        let cols = node{"columns"}.getInt(0)
        let (obj, boundary) = hex_grid_object(rows=rows, cols=cols, top=top, f=generate_object_translate)
        objs.add(boundary)
        for o in obj:
            objs.add(o)

    if node{"type"}.getStr() == "concentric":
        proc generate_object_scale(scale: float): Object =
            var o: Object = json_to_object(node{"object"}, sim)[0]
            return o.scale(scale)

        let min_scale = node{"scaling_function"}{"min_scale"}.getFloat(1.0)
        let max_scale = node{"scaling_function"}{"max_scale"}.getFloat(1.0)
        let steps = node{"scaling_function"}{"steps"}.getInt(1)
        let (obj, boundary) = concentric(min_scale=min_scale, max_scale=max_scale, steps=steps, f=generate_object_scale)
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

    if node{"type"}.getStr() == "uniform":
        let p0 = json_to_vec(node{"p0"}) 
        let p1 = json_to_vec(node{"p1"})
        let v0 = json_to_vec(node{"v0"}) 
        let v1 = json_to_vec(node{"v1"})
        let N = node{"N"}.getInt(0)
        return UniformParticles().initUniformParticles(p0=p0, p1=p1, v0=v0, v1=v1, N=N)

proc json_to_interrupt(node: JsonNode, sim: Simulation): Interrupt =
    if node{"type"}.getStr() == "maxsteps":
        let maxstep = node{"steps"}.getInt(0)
        return MaxSteps().initMaxSteps(max=maxstep)
    
    if node{"type"}.getStr() == "collision":
        let obj = json_to_object(node{"object"}, sim)[0]
        return Collision().initCollision(obj)
    
    if node{"type"}.getStr() == "max_collisions":
        let max = node{"max"}.getInt(0)
        return MaxCollisions().initMaxCollisions(max)

    if node{"type"}.getStr() == "stalled":
        return Stalled().initStalled()

proc json_to_interrupt_group*(node: JsonNode, sim: Simulation): ObserverGroup =
    var op_table = {"and": AndOp, "or": OrOp}.toTable()
    var op: BoolOp = OrOp
    var list_node: JsonNode = nil
    if node{"list"} != nil:
        list_node = node{"list"}
        op = op_table[node{"op"}.getStr("or")]
    else:
        list_node = node

    var interrupts: seq[Observer] = @[]
    for n in list_node:
        interrupts.add(json_to_interrupt(n, sim))
    return ObserverGroup().initObserverGroup(interrupts, op)

proc json_to_image_recorder*(img: ImageRecorder, node: JsonNode, sim: Simulation): Observer =
    let eqhist: NormFunction = proc(data: seq[float]): seq[float] =
        return image.eq_hist(data, nbins=256*256)
    let none: NormFunction = proc(data: seq[float]): seq[float] =
        return none_norm(data)

    let cmap_table = {"gray": gray, "gray_r": gray_r}.toTable()
    let norm_table = {"eq_hist": eqhist, "none": none}.toTable()
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
    let resolution = node{"resolution"}.getInt(100)
    let dpi = resolution.float / max(box.uu[0] - box.ll[0], box.uu[1] - box.ll[1]) 

    var triggers: ObserverGroup = nil
    if node{"triggers"} != nil:
        triggers = json_to_interrupt_group(node{"triggers"}, sim)

    let plotter = DensityPlot().initDensityPlot(box=box, dpi=dpi, blendmode=blend)
    let obs = img.initImageRecorder(
        filename=filename, plotter=plotter, format=format,
        cmap=cmap, norm=norm, triggers=triggers)
    return obs

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
        return SVGLinePlotImpl().initSVGLinePlot(filename=filename, box=box, lw=dpi)

    elif node{"type"}.getStr() == "pgm":
        let obs = json_to_image_recorder(ImageRecorderImpl(), node, sim)
        return obs

    elif node{"type"}.getStr() == "movie":
        let interval: int = node{"interval"}.getInt(1)
        var obs = json_to_image_recorder(PeriodicImageRecorderImpl(), node, sim)
        return obs.PeriodicImageRecorder.initPeriodicImageRecorder(interval)

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

    if node{"type"}.getStr() == "central":
        let c = json_to_vec(node{"pos"})
        let k = node{"k"}.getFloat()
        return generate_force_central(c, k)

proc json_to_threads*(json: string): int =
    var cfg = parseJson(json)
    if cfg{"simulation"} != nil:
        return cfg["simulation"]{"threads"}.getInt(1)
    return 1

proc json_to_simulation*(json: string, index: int = 0): Simulation =
    var sim = Simulation().initSimulation()

    var cfg = parseJson(json)
    if cfg{"simulation"} != nil:
        var s = cfg["simulation"]
        sim.eps = s{"eps"}.getFloat(1e-6)
        sim.dt = s{"dt"}.getFloat(1e-2)
        sim.max_steps = s{"max_steps"}.getInt(1)
        sim.threads = s{"threads"}.getInt(1)
        sim.verbose = s{"verbose"}.getBool(true)
        sim.linear = s{"linear"}.getBool(true)
        sim.equal_time = s{"equal_time"}.getBool(false)
        sim.accuracy_mode = s{"accuracy"}.getBool(false)
        sim.record_objects = s{"record_objects"}.getBool(false)

    if cfg{"objects"} != nil:
        for node in cfg{"objects"}:
            for obj in json_to_object(node, sim):
                sim.add_object(obj)

    if cfg{"particles"} != nil:
        for node in cfg{"particles"}:
            let partitions = json_to_particle(node, sim).partition(sim.threads)
            sim.add_particle(partitions[index])

    if cfg{"observers"} != nil:
        for node in cfg{"observers"}:
            sim.add_observer(json_to_observer(node, sim))

    if cfg{"interrupts"} != nil:
        sim.add_observer(json_to_interrupt_group(cfg{"interrupts"}, sim))

    if cfg{"forces"} != nil:
        for node in cfg{"forces"}:
            sim.add_force(json_to_force(node, sim))

    if cfg{"neighborlist"} != nil:
        sim.set_neighborlist(json_to_neighborlist(cfg{"neighborlist"}, sim))
    else:
        sim.set_neighborlist(Neighborlist())

    return sim