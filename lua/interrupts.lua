local observers = require('observers')
local util = require('util')

Interrupt = util.class(observers.Observer)
function Interrupt:is_triggered() return false end

-- ================================================================
MaxSteps = util.class(Interrupt)
function MaxSteps:init(max)
    self.max = max
    self.triggered = false
end

function MaxSteps:reset() self.triggered = false end
function MaxSteps:is_triggered() return self.triggered end

function MaxSteps:update_time(step)
    if step > self.max then
        self.triggered = true
    end
end

-- ================================================================
Collision = util.class(Interrupt)
function Collision:init(object)
    self.obj = object
    self.triggered = false
end

function Collision:reset() self.triggered = false end
function Collision:is_triggered() return self.triggered end

function Collision:update_collision(particle, object, time)
    if self.obj == object then
        self.triggered = true
    end
end

return {
    Interrupt = Interrupt,
    MaxSteps = MaxSteps,
    Collision = Collision
}
