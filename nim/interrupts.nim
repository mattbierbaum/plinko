import objects
import observers
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

method update_step*(self: MaxSteps, step: int): void =
    if step > self.max:
        self.triggered = true

# ================================================================
type
    MaxCollisions* = ref object of Interrupt
        max*: int
        collisions*: Table[int, int]
        seen*: Table[int, bool]
        not_triggered*: Table[int, bool]

proc initMaxCollisions*(self: MaxCollisions, max: int): MaxCollisions =
    self.max = max
    self.seen = initTable[int, bool]()
    self.collisions = initTable[int, int]()
    self.not_triggered = initTable[int, bool]()
    return self

method is_triggered*(self: MaxCollisions): bool = 
    if self.seen.len == 0 or self.not_triggered.len > 0:
        return false
    return true

method is_triggered_particle*(self: MaxCollisions, particle: PointParticle): bool = 
    if not self.seen.hasKey(particle.index):
        self.seen[particle.index] = true
        self.not_triggered[particle.index] = true
        self.collisions[particle.index] = 0
        return false
    return not self.not_triggered.hasKey(particle.index)

method update_collision*(self: MaxCollisions, particle: PointParticle, obj: Object, time: float): void =
    # actually trigger the individual particle
    let i = particle.index
    self.collisions[i] = self.collisions[i] + 1
    if self.collisions[i] > self.max:
        self.not_triggered.del(i)

method reset*(self: MaxCollisions): void =
    self.seen = initTable[int, bool]() 
    self.collisions = initTable[int, int]()
    self.not_triggered = initTable[int, bool]()

method `$`*(self: MaxCollisions): string = fmt"MaxCollisions: {self.max}"

# ================================================================
type
    Collision* = ref object of Interrupt
        obj*: Object
        seen*: Table[int, bool]
        not_triggered*: Table[int, bool]

proc initCollision*(self: Collision, obj: Object): Collision =
    self.obj = obj
    self.seen = initTable[int, bool]()
    self.not_triggered = initTable[int, bool]()
    return self

method is_triggered*(self: Collision): bool = 
    if self.seen.len == 0 or self.not_triggered.len > 0:
        return false
    return true

method is_triggered_particle*(self: Collision, particle: PointParticle): bool = 
    if not self.seen.hasKey(particle.index):
        self.seen[particle.index] = true
        self.not_triggered[particle.index] = true
        return false
    return not self.not_triggered.hasKey(particle.index)

method update_collision*(self: Collision, particle: PointParticle, obj: Object, time: float): void =
    # actually trigger the individual particle
    if self.obj == obj:
        self.not_triggered.del(particle.index)

method reset*(self: Collision): void =
    self.seen = initTable[int, bool]() 
    self.not_triggered = initTable[int, bool]()

method `$`*(self: Collision): string = fmt"Collision: {self.obj}"

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