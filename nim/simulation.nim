import vector
import objects
import forces
import neighborlist
import observers
import roots

let MAX_BOUNCE: int = 10000

type
    Simulation = ref object of RootObj
        t, dt, eps: float
        equal_time: bool
        accuracy_mode: bool
        objects: seq[Object]
        particle_groups: seq[ParticleGroup]
        force_func: seq[IndependentForce]
        observers: seq[Observer]
        observer_group: ObserverGroup
        integrator: Integrator
        nbl: Neighborlist

proc initSimulation*(self: Simulation, dt: float = 1e-12, eps: float = 1e-6): Simulation = 
    self.t = 0
    self.dt = dt
    self.eps = eps
    self.equal_time = false
    self.accuracy_mode = false
    self.objects = @[]
    self.particle_groups = @[]
    self.force_func = @[]
    self.observers = @[]
    self.integrator = integrate_velocity_verlet

proc add_object*(self: Simulation, obj: Object): void {.discardable.} =
    let index = self.objects.len
    obj.set_object_index(index)
    self.objects.add(obj)

proc add_particle*(self: Simulation, particle_group: ParticleGroup): void {.discardable.} =
    self.particle_groups.add(particle_group)

proc add_force*(self: Simulation, force: IndependentForce): void {.discardable.} =
    self.force_func.add(force)

proc add_observer*(self: Simulation, observer: Observer): void {.discardable.} =
    self.observers.add(observer)

proc initialize*(self: Simulation): void =
    self.observer_group = observers.ObserverGroup()
    discard self.observer_group.initObserverGroup(self.observers)
    self.observer_group.begin()

proc set_integrator*(self: Simulation, integrator: Integrator): void =
    self.integrator = integrator

proc set_neighborlist*(self: Simulation, nbl: Neighborlist): void =
    self.nbl = nbl
    for obj in self.objects:
        self.nbl.append(obj)
    self.nbl.calculate()

proc intersection_bruteforce*(self: Simulation, seg: Segment): (float, Object) =
    var mint = 2.0
    var mino: Object = nil

    for obj in self.objects:
        let (o, t) = obj.intersection(seg)
        if t < mint and t <= 1 and t > 0:
            mint = t
            mino = o

    return (mint, mino)

proc intersection*(self: Simulation, seg: Segment): (float, Object) =
    var mint = 2.0
    var mino: Object = nil

    let objs = self.nbl.near(seg)
    for obj in objs:
        let (o, t) = obj.intersection(seg)
        if t < mint and t <= 1 and t >= 0:
            mint = t
            mino = o
    return (mint, mino)

proc refine_intersection*(self: Simulation, part0: PointParticle, part1: PointParticle, obj: Object, dt: float): float =
    var s = objects.Segment()
    var project = objects.PointParticle()

    proc f(dt: float): float =
        self.integrator(part0, project, dt)
        s = Segment(p0: part0.pos, p1: project.pos)
        var (o, t) = obj.intersection(s)
        if t < 0 or t > 1:
            s = Segment(p0: project.pos, p1: part1.pos)
            (o, t) = obj.intersection(s)
        return lengthsq(project.pos - lerp(s.p0, s.p1, t))

    return f(0.0) # brent(f=f, bracket=[0, dt], tol=1e-12, maxiter=20)


proc intersection*(self: Simulation, part0: PointParticle, part1: PointParticle): (PointParticle, Object, float) =
    var mint: float = 2.0
    var mino: Object = nil
    var parti = PointParticle()

    var pseg = Segment(p0: part0.pos, p1: part1.pos)
    var objs = self.nbl.near(pseg)
    for obj in objs:
        let (o, t) = obj.intersection(pseg)
        if t < mint and t <= 1 and t >= 0:
            mint = t
            mino = o

    if mint < 0 or mint > 1:
        return (part0, nil, -1.0)

    if self.accuracy_mode:
        mint = self.refine_intersection(part0, part1, mino, self.dt)
        parti = self.integrator(part0, mint)
    else:
        mint = (1 - self.eps) * mint
        
        parti.pos = lerp(part0.pos, part1.pos, mint)
        parti.vel = lerp(part0.vel, part1.vel, mint)
    return (parti, mino, mint)

#[
proc linear_project*(self: Simulation, part0: PointParticle, part1: PointParticle): (PointParticle, bool) =
    var (parti, mino, mint) = self.intersection(part0, part1)
    self.observer_group.update_collision(parti, mino, mint)
    pseg, vseg = mino.collide(part0, parti, part1)

    if not self.equal_time:
        part0.pos = pseg.p0
        part0.vel = vseg.p0
        self.observer_group.update_particle(part0)

    return (parti, running)

proc step_particle*(self: Simulation, part0: PointParticle): void =
    self.observer_group.set_particle(part0)

    if not part0.active:
        return

    let part1 = self.integrator(part0, self.dt)
    let (parti, is_running) = self.linear_project(part0, part1)
    part0.copy(part1)
    self.observer_group.update_particle(part0)

    part0.active = (
        part0.active
        and is_running
        and not self.observer_group.is_triggered_particle(part0)
    )
    in_part.copy(part0)
]#