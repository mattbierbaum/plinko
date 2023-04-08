import forces
import neighborlist
import observers
import objects
import particles
import roots
import util
import vector

import std/strformat

type
    Simulation* = ref object of RootObj
        dt*, eps*: float
        brent_tol*, brent_mintol*: float
        brent_maxiter*: int
        max_steps*: int
        particle_steps*: int
        particle_collisions*: int
        threads*: int
        thread_index*: int
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
    self.dt = dt
    self.eps = eps
    self.brent_tol = 1e-15
    self.brent_mintol = 1e-30
    self.brent_maxiter = 30
    self.particle_steps = 0
    self.particle_collisions = 0
    self.max_steps = max_steps
    self.threads = 1
    self.thread_index = 0
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
    self.nbl = Neighborlist().initNeighborList()
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
    self.particle_groups.add(particle_group)

proc add_force*(self: Simulation, force: IndependentForce): void {.discardable.} =
    self.force_func.add(force)

proc add_observer*(self: Simulation, observer: Observer): void {.discardable.} =
    self.observers.add(observer)

proc add_interrupt*(self: Simulation, interrupt: Observer): void {.discardable.} =
    self.observers.add(interrupt)

proc partition*(self: Simulation): (int, int)=
    # Calculate the total number of particles up to the current thread index
    # to find the offset for particle labels.
    var start = 0
    var offset = 0
    for i in 0 .. self.thread_index - 1:
        for j in 0 .. self.particle_groups.len-1:
            self.particle_groups[j].partition(i, self.threads)
            offset += self.particle_groups[j].count()
    start = offset

    for j in 0 .. self.particle_groups.len-1:
        self.particle_groups[j].partition(self.thread_index, self.threads)
        offset = self.particle_groups[j].generate(offset)
    self.particle_index = offset
    return (start, offset - start)

proc initialize*(self: Simulation): void =
    let (offset, count) = self.partition()

    for obj in self.objects:
        self.nbl.append(obj)
    self.nbl.calculate()

    self.observer_group = ObserverGroup().initObserverGroup(self.observers)
    self.observer_group.set_particle_count(offset, count)
    self.observer_group.begin()

    if self.record_objects:
        for obj in self.objects:
            self.observer_group.record_object(obj)

proc clear_intermediates*(self: Simulation): void =
    self.nbl = nil
    self.objects = @[]
    self.force_func = @[]
    self.particle_groups = @[]
    self.observer_group.clear_intermediates()

proc set_integrator*(self: Simulation, integrator: Integrator): void =
    self.integrator = integrator

proc set_neighborlist*(self: Simulation, nbl: Neighborlist): void =
    self.nbl = nbl

proc intersect_objects*(self: Simulation, seg: Seg): (float, Object, bool) =
    var mint = 2.0
    var mino: Object = nil

    if not self.nbl.contains(seg):
        return (-1.0, nil, false)
    let nblobj = self.nbl.near(seg)
    for i in 0 .. nblobj.count - 1:
        let (o, t) = nblobj.objs[i].intersection(seg)
        self.particle_collisions += 1
        if t < mint and t <= 1 and t >= 0:
            mint = t
            mino = o
    if mint >= 0 and mint <= 1:
        return (mint, mino, true)
    return (-1.0, nil, true)

proc refine_intersection*(self: Simulation, part0: PointParticle, part1: PointParticle, obj: Object, dt: float): float =
    var seg = Seg()
    proc f(dt: float): float =
        let project = self.integrator(part0, dt)
        seg.p0 = part0.pos
        seg.p1 = project.pos
        var (o, t) = obj.intersection(seg)
        self.particle_collisions += 1
        if t < 0 or t > 1:
            seg.p0 = project.pos
            seg.p1 = part1.pos
            (o, t) = obj.intersection(seg)
            self.particle_collisions += 1
            if t < 0 or t > 1:
                return -1.0
        return lengthsq(project.pos - lerp(seg.p0, seg.p1, t))
    return roots.brent(f=f, bracket=[0.0, 2*dt], tol=self.brent_tol, mintol=self.brent_mintol, maxiter=self.brent_maxiter)

proc lerp*(a: float, b: float, t: float): float {.inline.} = (1-t)*a + t*b

proc intersection*(self: Simulation, part0: PointParticle, part1: PointParticle): (PointParticle, Object, float, bool) =
    var gparti = PointParticle()
    gparti.copy(part0)
    var seg = Seg(p0: part0.pos, p1: part1.pos)
    var (mint, mino, ok) = self.intersect_objects(seg)

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
        gparti.time = lerp(part0.time, part1.time, mint)
    return (gparti, mino, mint, true)

proc collide*(self: Object, part0: PointParticle, parti: PointParticle, part1: PointParticle): (Seg, Seg) =
    var scoll = Seg(p0: part0.pos, p1: parti.pos)
    var stotal = Seg(p0: parti.pos, p1: part1.pos)
    var vseg = Seg(p0:parti.vel, p1:part1.vel)

    if self.damp < 0:
        vseg.p0 = vseg.p0 * abs(self.damp)
        vseg.p1 = vseg.p1 * abs(self.damp)
        return (stotal, vseg)

    let norm = self.normal(scoll)
    let dir = reflect(part1.pos - parti.pos, norm)
    stotal.p1 = parti.pos + dir
    vseg.p0 = reflect(vseg.p0, norm) * self.damp
    vseg.p1 = reflect(vseg.p1, norm) * self.damp
    return (stotal, vseg)

proc step_collisions*(self: Simulation, part0: PointParticle, part1: PointParticle, depth: int = 0): (PointParticle, bool) =
    var parta = part0
    var partb = part1
    var (parti, mino, mint, ok) = self.intersection(parta, partb)

    if not ok or depth > 10000:
        return (partb, false)
    if mino == nil:
        return (partb, true)

    self.observer_group.update_collision(parti, mino, mint)
    let (pseg, vseg) = mino.collide(parta, parti, partb)
    parta.pos = pseg.p0
    parta.vel = vseg.p0 
    parta.time = parti.time

    if not self.equal_time:
        self.observer_group.update_particle(parta)

    if self.linear:
        partb.pos = pseg.p1
        partb.vel = vseg.p1
        partb.time = part1.time
        return self.step_collisions(parta, partb, depth=depth+1)
    return (parta, true)

proc step_particle*(self: Simulation, part0: var PointParticle): void =
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
        for j in 0 .. self.particle_groups.len-1:
            for i in 0 .. self.particle_groups[j].count()-1:
                var p = self.particle_groups[j].index(i)
                p.acc = self.force_func[0](p)
                self.step_particle(p)
                self.particle_groups[j].copy(i, p)

        self.observer_group.update_step(step)
        if self.observer_group.is_triggered():
            break

proc `$`*(self: Simulation): string =
    var o = ""
    o = o & fmt"Simulation: dt={self.dt} eps={self.eps} steps={self.max_steps}" & "\n"
    for obj in self.objects:
        o &= &"  o: {$obj}\n"
    for obj in self.particle_groups:
        o &= indent($obj)
    o &= indent($self.observer_group)
    o &= indent($self.nbl)
    return o

proc run*(self: Simulation): void =
    self.step(self.max_steps)

proc close*(self: Simulation): void =
    self.observer_group.close()