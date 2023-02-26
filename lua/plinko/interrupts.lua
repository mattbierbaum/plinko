local observers = require('plinko.observers')
local util = require('plinko.util')

local Interrupt = util.class(observers.Observer)
function Interrupt:is_triggered() return false end
function Interrupt:is_triggered_particle() return false end

-- ================================================================
local MaxSteps = util.class(Interrupt)
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
local Collision = util.class(Interrupt)
function Collision:init(object)
    self.obj = object
    self.triggers = nil
    self.triggered = false
end

function Collision:reset()
    self.triggers = nil
    self.triggered = false
end

function Collision:is_triggered()
    return self.triggered
end

function Collision:_triggered()
    if self.triggers == nil then
        return false
    end

    local all = true
    for i = 1, #self.triggers do
        all = all and self.triggers[i]
    end

    return all
end

function Collision:is_triggered_particle(particle)
    if self.triggers == nil then return false end
    return self.triggers[particle.index]
end

function Collision:update_collision(particle, object, time)
    local ind = particle.index

    -- need to set to at least one value
    if self.triggers == nil then
        self.triggers = {}
    end

    if self.triggers[ind] == nil then
        self.triggers[ind] = false
    end

    -- actually trigger the individual particle
    if self.obj == object then
        self.triggers[ind] = true
        self.triggered = self:_triggered()
    end
end

return {
    Interrupt = Interrupt,
    MaxSteps = MaxSteps,
    Collision = Collision
}
