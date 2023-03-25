import objects
import observers
import particles
import util
import vector

import std/strformat
import std/tables

type
    Interrupt* = ref object of Observer

# ================================================================
type
    MaxSteps* = ref object of Interrupt
        max*: int
        triggered*: bool

proc initMaxSteps*(self: MaxSteps, max: int = 0): MaxSteps =
    self.max = max
    self.triggered = false
    return self

method reset*(self: MaxSteps): void = self.triggered = false
method is_triggered*(self: MaxSteps): bool = return self.triggered
method is_triggered_particle*(self: MaxSteps, particle: PointParticle): bool = return self.triggered

method update_step*(self: MaxSteps, step: int): void =
    if step > self.max:
        self.triggered = true

# ================================================================
type
    PerParticleInterrupt* = ref object of Interrupt
        triggered*: Pmt[bool]
        active: int
        any_seen: bool

proc initPerParticleInterrupt*(self: PerParticleInterrupt): PerParticleInterrupt =
    self.triggered = Pmt[bool]()
    self.any_seen = false
    self.active = 0

method set_particle_count*(self: PerParticleInterrupt, offset: int, count: int): void =
    self.triggered = Pmt[bool]().initPmt(offset, count)

method is_triggered*(self: PerParticleInterrupt): bool = 
    if self.any_seen and self.active == 0:
        return true
    return false

method is_triggered_particle*(self: PerParticleInterrupt, particle: PointParticle): bool = 
    let i = particle.index
    if not self.triggered.seen(i):
        self.active += 1
        self.triggered.set(i, false)
    else:
        self.any_seen = true
    return self.triggered.get(i)

proc trigger*(self: PerParticleInterrupt, particle: PointParticle): void =
    let i = particle.index
    if self.triggered.seen(i) and not self.triggered.get(i):
        self.active -= 1
        self.triggered.set(i, true)

# ================================================================
type
    MaxCollisions* = ref object of PerParticleInterrupt
        max*: int
        counter*: CollisionCounter

proc initMaxCollisions*(self: MaxCollisions, max: int): MaxCollisions =
    self.max = max
    self.counter = CollisionCounter().initCollisionCounter()
    discard self.initPerParticleInterrupt()
    return self

method set_particle_count*(self: MaxCollisions, offset: int, count: int): void =
    procCall self.PerParticleInterrupt.set_particle_count(offset, count)
    self.counter.set_particle_count(offset, count)

method update_collision*(self: MaxCollisions, particle: PointParticle, obj: Object, time: float): void =
    self.counter.update_collision(particle, obj, time)
    if self.counter.num_collisions(particle) >= self.max:
        self.trigger(particle)

method reset*(self: MaxCollisions): void =
    procCall self.PerParticleInterrupt.reset()
    self.counter.reset()

method `$`*(self: MaxCollisions): string = fmt"MaxCollisions: {self.max}"

# ================================================================
type
    Collision* = ref object of PerParticleInterrupt
        counter*: CollisionCounter

proc initCollision*(self: Collision, obj: Object): Collision =
    self.counter = CollisionCounter().initCollisionCounter(obj=obj)
    discard self.initPerParticleInterrupt()
    return self

method set_particle_count*(self: Collision, offset: int, count: int): void =
    procCall self.PerParticleInterrupt.set_particle_count(offset, count)
    self.counter.set_particle_count(offset, count)

method update_collision*(self: Collision, particle: PointParticle, obj: Object, time: float): void =
    self.counter.update_collision(particle, obj, time)
    if self.counter.num_collisions(particle) >= 1:
        self.trigger(particle)

method reset*(self: Collision): void =
    procCall self.PerParticleInterrupt.reset()
    self.counter.reset()

method `$`*(self: Collision): string = fmt"Collision: {self.counter.obj}"

# ================================================================
type
    Stalled* = ref object of Interrupt
        triggered*: bool
        triggers*: Table[int, bool]
        zero_streak*: Table[int, int]
        interval*: int
        count*: int
        step*: int

proc initStalled*(self: Stalled, count: int = 100, interval: int = 10000): Stalled =
    self.step = 0
    self.interval = interval
    self.count = count
    self.triggered = false
    self.triggers = initTable[int, bool]()
    self.zero_streak = initTable[int, int]()
    return self

proc calc_triggered(self: Stalled): bool =
    if self.triggers.len == 0:
        return false

    var all = true
    for i, trigger in self.triggers:
        all = all and trigger

    return all

method is_triggered*(self: Stalled): bool = return self.triggered 

method is_triggered_particle*(self: Stalled, particle: PointParticle): bool = 
    if particle.index notin self.triggers:
        return false
    return self.triggers[particle.index]

method update_particle*(self: Stalled, particle: PointParticle): void =
    # actually trigger the individual particle
    self.step = self.step + 1
    if (self.step mod self.interval) != 0:
        return

    let i = particle.index
    if length(particle.vel) < 1e-6:
        let z = self.zero_streak[i]
        if z >= self.count:
            self.triggers[particle.index] = true
            self.triggered = self.calc_triggered()
        self.zero_streak[i] = z + 1
    else:
        self.zero_streak[i] = 0

method reset*(self: Stalled): void = 
    self.zero_streak = initTable[int, int]()
    self.triggers = initTable[int, bool]()
    self.triggered = false

method `$`*(self: Stalled): string = fmt"Stalled: {self.interval} {self.count}"