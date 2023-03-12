import objects
import observers
import particles
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
        seen*: Table[int, bool]
        not_triggered*: Table[int, bool]

proc initPerParticleInterrupt*(self: PerParticleInterrupt): PerParticleInterrupt =
    self.seen = initTable[int, bool]()
    self.not_triggered = initTable[int, bool]()

method is_triggered*(self: PerParticleInterrupt): bool = 
    if self.seen.len == 0 or self.not_triggered.len > 0:
        return false
    return true

method is_triggered_particle*(self: PerParticleInterrupt, particle: PointParticle): bool = 
    if not self.seen.hasKey(particle.index):
        self.seen[particle.index] = true
        self.not_triggered[particle.index] = true
        return false
    return not self.not_triggered.hasKey(particle.index)

proc trigger*(self: PerParticleInterrupt, particle: PointParticle): void =
    self.seen[particle.index] = true
    self.not_triggered.del(particle.index)

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