import objects
import observers
import vector

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

method update_step*(self: MaxSteps, step: int): void =
    if step > self.max:
        self.triggered = true

# ================================================================
type
    Collision* = ref object of Interrupt
        obj*: Object
        triggered*: bool
        triggers*: Table[int, bool]

proc initCollision*(self: Collision, obj: Object): Collision =
    self.obj = obj
    self.triggered = false
    self.triggers = initTable[int, bool]()
    return self

proc calc_triggered(self: Collision): bool =
    if self.triggers.len == 0:
        return false

    var all = true
    for i, trigger in self.triggers:
        all = all and trigger

    return all

method is_triggered*(self: Collision): bool = return self.triggered 

method is_triggered_particle*(self: Collision, particle: PointParticle): bool = 
    if particle.index notin self.triggers:
        return false
    return self.triggers[particle.index]

method update_collision*(self: Collision, particle: PointParticle, obj: Object, time: float): void =
    # actually trigger the individual particle
    if self.obj == obj:
        self.triggers[particle.index] = true
        self.triggered = self.calc_triggered()

method reset*(self: Collision): void =
    self.triggers = initTable[int, bool]()
    self.triggered = false

# ================================================================
type
    Stalled* = ref object of Interrupt
        triggered*: bool
        triggers*: Table[int, bool]
        zero_streak*: Table[int, int]
        interval*: int
        step*: int

proc initStalled*(self: Stalled, interval: int = 1000): Stalled =
    self.step = 0
    self.interval = interval
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
    if (self.step mod self.interval) == 0:
        return

    if length(particle.vel) < 1e-12:
        let i = particle.index
        let z = self.zero_streak[i]

        self.zero_streak[i] = z + 1
        if z > 1000:
            self.triggers[particle.index] = true
            self.triggered = self.calc_triggered()

method reset*(self: Stalled): void = 
    self.zero_streak = initTable[int, int]()
    self.triggers = initTable[int, bool]()
    self.triggered = false
