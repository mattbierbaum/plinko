import objects
import observers

type
    Interrupt = ref object of Observer
proc is_triggered*(self: Interrupt): bool = false
proc is_triggered_particle*(self: Interrupt): bool = false

# ================================================================
type
    MaxSteps* = ref object of Interrupt
        max*: float
        triggered*: bool

proc initMaxSteps*(self: MaxSteps, max: float = 0): void =
    self.max = max
    self.triggered = false

proc reset*(self: MaxSteps): void = self.triggered = false
proc is_triggered*(self: MaxSteps): bool = return self.triggered

proc update_time*(self: MaxSteps, step: float): void =
    if step > self.max:
        self.triggered = true

# ================================================================
type
    Collision* = ref object of Interrupt
        obj*: Object
        triggered*: bool

proc initCollision*(self: Collision, obj: Object): void =
    self.obj = obj
    self.triggered = false

proc reset*(self: Collision): void = self.triggered = false
proc is_triggered*(self: Collision): bool = return self.triggered 
proc is_triggered_particle*(self: Collision): bool = return self.triggered

proc update_collision*(self: Collision, particle: PointParticle, obj: Object, time: float): void =
    # actually trigger the individual particle
    if self.obj == obj:
        self.triggered = true
