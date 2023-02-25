import vector
import objects
import forces
import observers
import neighborlist
import simulation

import std/json
import std/math

type ObjectGenerator = proc(pos: Vec): Object

proc hex_grid_object*(rows: int, cols: int, f: ObjectGenerator): (seq[Object], Vec) =
    var a = 1.0
    var rt3 = math.sqrt(3.0)

    var objs: seq[Object] = @[]
    for i in 0 .. rows-1:
        for j in 0 .. cols-1:
            if (i.float*a*rt3 >= 1e-10):
                objs.add(f([j.float*a, i.float*a*rt3]))

            if not (j == cols - 1):
                objs.add(f([(j.float+0.5)*a, (i.float+0.5)*a*rt3]))

    let boundary = [(cols.float-1.0)*a, (rows.float+1)*rt3*a]
    return (objs, boundary)

proc square_grid_object*(rows: int, cols: int, f: ObjectGenerator): (seq[Object], Vec) =
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
    return Box().initBox(ll=ll, uu=uu, damp=damp)

proc json_to_circle(node: JsonNode, sim: Simulation): Circle =
    let pos = json_to_vec(node{"pos"})
    let rad = node{"rad"}.getFloat()
    let damp = node{"damp"}.getFloat()
    return Circle().initCircle(pos=pos, rad=rad, damp=damp)

proc json_to_object(node: JsonNode, sim: Simulation): seq[Object] =
    var objs: seq[Object] = @[]
    if node{"type"}.getStr() == "circle":
        objs.add(json_to_circle(node, sim))

    if node{"type"}.getStr() == "box":
        objs.add(json_to_box(node, sim))

    if node{"type"}.getStr() == "ref":
        let index = node{"index"}.getInt()
        objs.add(sim.objects[index])

    if node{"type"}.getStr() == "tri-lattice":
        proc generate_object(pos: Vec): Object =
            var o: Object = json_to_object(node{"object"}, sim)[0]
            o = o.translate(-o.center())
            o = o.translate(pos)
            return o
        let rows = node{"rows"}.getInt(0)
        let cols = node{"columns"}.getInt(0)
        let (obj, _) = hex_grid_object(rows=rows, cols=cols, f=generate_object)
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
    if node{"type"}.getStr() == "svg":
        let filename = node{"filename"}.getStr()
        let box = json_to_box(node{"box"}, sim)
        let lw = node{"lw"}.getFloat()
        return SVGLinePlot().initSVGLinePlot(filename=filename, box=box, lw=lw)

proc json_to_neighborlist(node: JsonNode, sim: Simulation): Neighborlist =
    if node{"type"}.getStr() == "naive":
        return Neighborlist()
    if node{"type"}.getStr() == "cell":
        let box = json_to_box(node{"box"}, sim)
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
        sim.eps = s["eps"].getFloat(1e-6)
        sim.dt = s["dt"].getFloat(1e-2)
        sim.max_steps = s["max_steps"].getInt(1)
        sim.equal_time = s["equal_time"].getBool(true)
        sim.accuracy_mode = s["accuracy"].getBool(false)

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