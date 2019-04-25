local util = require('plinko.util')
local observers = require('plinko.observers')

LoveLineObserver = util.class(observers.Observer)
function LoveLineObserver:init(alpha)
    self.lastposition = nil
    self.alpha = alpha
    self.canvas = love.graphics.newCanvas()
end

function LoveLineObserver:begin()
    self.lastposition = nil
end

function LoveLineObserver:set_particle(p)
    self.lastposition = nil
end

function LoveLineObserver:reset()
    self.lastposition = nil
end

function LoveLineObserver:update_time(t) end
function LoveLineObserver:update_collision() end
function LoveLineObserver:is_triggered() end
function LoveLineObserver:close() end

function LoveLineObserver:update_particle(particle)
    if not self.lastposition then
        self.lastposition = {particle.pos[1], particle.pos[2]}
    else
        self.canvas:renderTo(function()
            love.graphics.setColor(0, 0, 0, self.alpha)
            love.graphics.line(self.lastposition[1], self.lastposition[2], particle.pos[1], particle.pos[2])
        end)
        self.lastposition[1] = particle.pos[1]
        self.lastposition[2] = particle.pos[2]
    end
end

return {LoveLineObserver=LoveLineObserver}
