import forces
import neighborlist
import observers
import objects
import particles
import roots
import vector

import std/strformat

type
    Simulation* = ref object of RootObj
        t, dt*, eps*: float
        max_steps*: int
        particle_steps*: int
        threads*: int
        verbose*: bool
        linear*: bool
        equal_time*: bool
        accuracy_mode*: bool
        record_objects*: bool
        objects*: seq[Object]
        particle_index*: int
        particle_groups*: seq[ParticleGroup]
        force_func*: seq[IndependentForce]
        observers*: seq[Observer]
        observer_group*: ObserverGroup
        integrator*: Integrator
        nbl*: Neighborlist

proc initSimulation*(self: Simulation, dt: float = 1e-2, eps: float = 1e-6, max_steps: int = 1e6.int): Simulation = 
    self.t = 0
    self.dt = dt
    self.eps = eps
    self.particle_steps = 0
    self.max_steps = max_steps
    self.threads = 1
    self.verbose = true
    self.linear = true
    self.equal_time = false
    self.accuracy_mode = false
    self.record_objects = false
    self.objects = @[]
    self.particle_index = 0
    self.particle_groups = @[]
    self.force_func = @[]
    self.observers = @[]
    self.integrator = integrate_velocity_verlet
    self.nbl = Neighborlist()
    return self

proc object_by_name*(self: Simulation, name: string): Object =
    for obj in self.objects:
        let tmp = obj.by_name(name)
        if tmp != nil:
            return tmp

proc add_object*(self: Simulation, obj: Object): void =
    let index = self.objects.len
    obj.set_index(index)
    self.objects.add(obj)

proc add_particle*(self: Simulation, particle_group: ParticleGroup): void {.discardable.} =
    if particle_group == nil:
        return
    self.particle_index = particle_group.set_indices(self.particle_index)
    self.particle_groups.add(particle_group)

proc add_force*(self: Simulation, force: IndependentForce): void {.discardable.} =
    self.force_func.add(force)

proc add_observer*(self: Simulation, observer: Observer): void {.discardable.} =
    self.observers.add(observer)

proc add_interrupt*(self: Simulation, interrupt: Observer): void {.discardable.} =
    self.observers.add(interrupt)

proc initialize*(self: Simulation): void =
    for obj in self.objects:
        self.nbl.append(obj)
    self.nbl.calculate()

    self.observer_group = ObserverGroup().initObserverGroup(self.observers)
    self.observer_group.begin()

    if self.record_objects:
        for obj in self.objects:
            self.observer_group.record_object(obj)

proc partition*(self: Simulation, index: int): void =
    # Chew through all threads < index to increment the particle index properly.
    # Then, keep the particles for the correct partition index.
    var original_particles: seq[ParticleGroup] = @[]
    for p in self.particle_groups:
        original_particles.add(p)

    self.particle_index = 0
    for i in 0 .. self.threads - 1:
        self.particle_groups = @[]
        for p in original_particles:
            self.add_particle(p.partition(self.threads)[i])
        if i == index:
            break

proc set_integrator*(self: Simulation, integrator: Integrator): void =
    self.integrator = integrator

proc set_neighborlist*(self: Simulation, nbl: Neighborlist): void =
    self.nbl = nbl

proc intersect_objects*(self: Simulation, seg: Segment): (float, Object, bool) =
    var mint = 2.0
    var mino: Object = nil

    if not self.nbl.contains(seg):
        return (-1.0, nil, false)
    let objs = self.nbl.near(seg)
    for obj in objs:
        let (o, t) = obj.intersection(seg)
        if t < mint and t <= 1 and t >= 0:
            mint = t
            mino = o
    if mint >= 0 and mint <= 1:
        return (mint, mino, true)
    return (-1.0, nil, true)

proc refine_intersection*(self: Simulation, part0: PointParticle, part1: PointParticle, obj: Object, dt: float): float =
    var gs = objects.Segment()
    proc f(dt: float): float =
        let project = self.integrator(part0, dt)
        gs.p0 = part0.pos
        gs.p1 = project.pos
        var (o, t) = obj.intersection(gs)
        if t < 0 or t > 1:
            gs.p0 = project.pos
            gs.p1 = part1.pos
            (o, t) = obj.intersection(gs)
            if t < 0 or t > 1:
                return -1.0
        return lengthsq(project.pos - lerp(gs.p0, gs.p1, t))
    return roots.brent(f=f, bracket=[0.0, 2*dt], tol=1e-20, mintol=1e-20, maxiter=10)

proc intersection*(self: Simulation, part0: PointParticle, part1: PointParticle): (PointParticle, Object, float, bool) =
    var gparti = PointParticle().copy(part0)
    var gpseg = Segment(p0: part0.pos, p1: part1.pos)
    var (mint, mino, ok) = self.intersect_objects(gpseg)

    if not ok:
        return (part0, nil, -1.0, false)
    if mint < 0 or mint > 1:
        return (part0, nil, -1.0, true)

    if self.accuracy_mode:
        mint = self.refine_intersection(part0, part1, mino, self.dt)
        if mint < 0 or mint > 1:
            return (part0, nil, -1.0, true)
        gparti = self.integrator(part0, (1 - mino.buffer_sign * self.eps)*mint)
    else:
        mint = (1 - mino.buffer_sign * self.eps) * mint
        gparti.pos = lerp(part0.pos, part1.pos, mint)
        gparti.vel = lerp(part0.vel, part1.vel, mint)
    return (gparti, mino, mint, true)

proc step_collisions*(self: Simulation, part0: PointParticle, part1: PointParticle, depth: int = 0): (PointParticle, bool) =
    var (parti, mino, mint, ok) = self.intersection(part0, part1)

    if not ok or depth > 10000:
        return (part1, false)
    if mino == nil:
        return (part1, true)

    self.observer_group.update_collision(parti, mino, mint)
    let (pseg, vseg) = mino.collide(part0, parti, part1)
    part0.pos = pseg.p0
    part0.vel = vseg.p0 

    if not self.equal_time:
        self.observer_group.update_particle(part0)

    if self.linear:
        part1.pos = pseg.p1
        part1.vel = vseg.p1
        return self.step_collisions(part0, part1, depth=depth+1)
    return (part0, true)

proc step_particle*(self: Simulation, part0: PointParticle): void =
    self.observer_group.set_particle(part0)

    if not part0.active:
        return

    self.particle_steps += 1
    let part1 = self.integrator(part0, self.dt)
    let (parti, is_running) = self.step_collisions(part0, part1)
    let active = (
        part0.active and 
        is_running and 
        not self.observer_group.is_triggered_particle(part0)
    )

    part0.copy(parti)
    part0.active = active
    self.observer_group.update_particle(part0)

proc step*(self: Simulation, steps: int = 1): void =
    for step in 0 .. steps:
        for particles in self.particle_groups:
            for particle in particles.items():
                particle.acc = self.force_func[0](particle)

            for particle in particles.items():
                self.step_particle(particle)

        self.t = self.t + self.dt
        self.observer_group.update_time(self.t)
        self.observer_group.update_step(step)

        if self.observer_group.is_triggered():
            break

proc `$`*(self: Simulation): string =
    var o = ""
    o = o & fmt"Simulation: dt={self.dt} eps={self.eps} steps={self.max_steps}" & "\n"
    for obj in self.objects:
        o &= &"  o: {$obj}\n"
    for obj in self.particle_groups:
        o &= &"{$obj}\n"
    o &= $self.observer_group
    o &= $self.nbl
    return o

proc run*(self: Simulation): void =
    self.step(self.max_steps)

proc close*(self: Simulation): void =
    self.observer_group.close()