local ffi = require('ffi')
local ics = require('ics')
local vector = require('vector')
local objects = require('objects')
local forces = require('forces')
local neighborlist = require('neighborlist')
local observers = require('observers')
local interrupts = require('interrupts')
local plotting_image = require('plotting_image')
local util = require('util')
local obs = require('obs')

function clip(x)
    return x < 0 and 0 or (x > 1 and 1 or x)
end

LoveImageObserver = util.class(plotting_image.DensityPlot)
function LoveImageObserver:init(w, h, alpha)
    plotting_image.DensityPlot.init(self, objects.Box({0, 0}, {w, h}), 1)

    self.lastposition = nil
    self.segment = objects.Segment({0, 0}, {1, 1})

    self.w = w
    self.h = h
    self.data = love.image.newImageData(w, h)
    self.image = love.graphics.newImage(self.data)
    self.raw = ffi.cast("uint8_t*", self.data:getPointer())
    self.alpha = alpha

    self.data:mapPixel(function(x, y, r, g, b, a) return 1, 1, 1, 1 end)
end

function LoveImageObserver:begin()
    self.lastposition = nil
end

function LoveImageObserver:set_particle(p)
    self.lastposition = nil
    --self.lastposition[1] = p.pos[1]
    --self.lastposition[2] = p.pos[2]
end

function LoveImageObserver:reset()
    self.lastposition = nil
end

function LoveImageObserver:update_time(t) end
function LoveImageObserver:update_collision() end
function LoveImageObserver:is_triggered() end
function LoveImageObserver:close() end

function LoveImageObserver:update_particle(particle)
    if not self.lastposition then
        self.lastposition = {particle.pos[1], particle.pos[2]}
    else
        self.segment.p0[1] = self.lastposition[1]
        self.segment.p0[2] = self.lastposition[2]
        self.segment.p1[1] = particle.pos[1]
        self.segment.p1[2] = particle.pos[2]
        self:draw_segment(self.segment)

        self.lastposition[1] = particle.pos[1]
        self.lastposition[2] = particle.pos[2]
    end
end

function LoveImageObserver:_plot(x, y, c)
    local x = math.floor(x)
    --local y = math.floor(y)
    local y = self.h - math.floor(y)

    if x < 0 or x >= self.N[1] or y < 0 or y >= self.N[2] then
        return
    end

    --local ind = x*4 + self.N[1]*4*y
    --self.raw[ind + 0] = clip(self.raw[ind + 0] - c*self.alpha)
    --self.raw[ind + 1] = clip(self.raw[ind + 1] - c*self.alpha)
    --self.raw[ind + 2] = clip(self.raw[ind + 2] - c*self.alpha)
    local r, g, b, a = self.data:getPixel(x, y)
    r = clip(r - c*self.alpha)
    g = clip(g - c*self.alpha)
    b = clip(b - c*self.alpha)
    self.data:setPixel(x, y, r, g, b, a)
end

function level0()
    local w, h, flags = love.window.getMode()
    local _obs = LoveImageObserver(w, h, 0.01)
    --local _obs = obs.LoveLineObserver(0.1)

    local p0 = {w/2, h-20}
    local p1 = p0 --vector.vaddv(p0, {1, 1})
    local v0 = {0.01*w, 0.01*h}
    local v1 = {0.011*w, 0.01*h}

    local conf = {
        dt = 1e-1,
        eps = 1e-4,
        nbl = neighborlist.CellNeighborlist(objects.Box({0, 0}, {w, h}), {100, 100}),
        forces = {forces.force_gravity},
        --particles = {objects.SingleParticle(p0, v0, {0, 0})},
        particles = {objects.UniformParticles(p0, p1, v0, v1, 2000)},
        objects = {
            objects.Box({0, 0}, {w, h}),
            --objects.Circle({w/2, h/2}, 300),
            --objects.Circle({w/4, h/2}, 100),
            --objects.Circle({3*w/4, h/2}, 100)
        },
        observers = {_obs}
    }
    
    local s = ics.create_simulation(conf)
    return s, _obs
end


return {level0 = level0}
