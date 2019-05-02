local util = require('plinko.util')
local vector = require('plinko.vector')
local objects = require('plinko.objects')

local Observer = util.class()
function Observer:init() end
function Observer:begin() end
function Observer:set_particle(particle) end
function Observer:update_particle(particle) end
function Observer:update_time(time) end
function Observer:update_collision(particle, object, time) end
function Observer:is_triggered() return false end
function Observer:is_triggered_particle(particle) return false end
function Observer:reset() end
function Observer:close() end

-- =================================================================
local StateFileRecorder = util.class(Observer)
function StateFileRecorder:init(filename)
    self.filename = filename
end

function StateFileRecorder:begin()
    self.file = io.open(self.filename, 'w')
end

function StateFileRecorder:update_particle(particle)
    local pos = particle.pos
    local vel = particle.vel
    local acc = particle.acc
    self.file:write(
        string.format('%f %f %f %f %f %f\n',
            pos[1], pos[2], vel[1], vel[2], acc[1], acc[2]
        )
    )
end

function StateFileRecorder:close()
    self.file:flush()
    self.file:close()
end

-- =================================================================
local ImageRecorder = util.class(Observer)
function ImageRecorder:init(filename, plotter, format)
    self.format = format or 'pgm5'
    self.filename = filename
    self.plotter = plotter
    self.lastposition = {}
    self.segment = objects.Segment({0,0}, {0,0})
end

function ImageRecorder:begin()
end

function ImageRecorder:update_particle(particle)
    local ind = particle.index
    local lastposition = self.lastposition[ind]

    if lastposition then
        self.segment.p0[1] = lastposition[1]
        self.segment.p0[2] = lastposition[2]
        self.segment.p1[1] = particle.pos[1]
        self.segment.p1[2] = particle.pos[2]

        self.plotter:draw_segment(self.segment)
        lastposition[1] = particle.pos[1]
        lastposition[2] = particle.pos[2]
    else
        self.lastposition[ind] = {particle.pos[1], particle.pos[2]}
    end
end

function ImageRecorder:reset()
    self.lastposition = {}
end

function ImageRecorder:close()
    if self.format == 'csv' then
        self.plotter:save_csv(self.filename)
    end
    if self.format == 'bin' then
        self.plotter:save_bin(self.filename)
    end
    if self.format == 'pgm5' then
        self.plotter:save_pgm5(self.filename)
    end
end

-- =================================================================
local PointImageRecorder = util.class(ImageRecorder)
function PointImageRecorder:init(filename, plotter)
    ImageRecorder.init(self, filename, plotter)
end

function PointImageRecorder:update_particle(particle)
    self.plotter:draw_point(particle.pos)
end

-- ========================================================
local SVGLinePlot = util.class(Observer)

local SVG_HEADER = [[<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="%fin" height="%fin" viewBox="%f %f %f %f"
     style="background-color:white;"
><rect width="100%%" height="100%%" fill="white"/><g>
]]
local SVG_PATH_STR = '<path style="fill:none;stroke:#000000;stroke-width:%fin;stroke-opacity:%f" d="'
local SVG_PATH_END = '"/>\n'
local SVG_FOOTER = '</g></svg>'

function SVGLinePlot:init(filename, box, lw, opacity, crosspath)
    self.filename = filename
    self.box = box
    self.lw = lw
    self.opacity = opacity ~= nil and opacity or 1.0
    self.crosspath = crosspath
    self.lastpt = {}
    self.lastind = -1
    self.breakpt = 10000
    self.y0 = self.box.ll[2]
    self.y1 = self.box.uu[2]
end

function SVGLinePlot:begin()
    self.count = 0
    self.file = io.open(self.filename, 'w')
    self.file:write(
        string.format(
            SVG_HEADER,
            self.box.uu[1] - self.box.ll[1],
            self.box.uu[2] - self.box.ll[2],
            self.box.ll[1], self.box.ll[2],
            self.box.uu[1], self.box.uu[2]
        )
    )
end

function SVGLinePlot:reflect(p)
    return {p[1], (self.y1 - p[2]) + self.y0}
end

function SVGLinePlot:update_particle(particle)
    local ind = particle.index
    local pos = particle.pos

    local lind = self.lastind
    local lpos = self.lastpt[ind]
    local pt = lpos and lpos or pos
    pt = self:reflect(pt)
    pos = self:reflect(pos)

    if self.count == 0 then
        self.file:write(string.format(SVG_PATH_STR, self.lw, self.opacity))
        self.file:write(string.format('M%f,%f ', pt[1], pt[2]))
    else
        if self.crosspath or (lind == ind) then
            self.file:write(string.format('L%f,%f ', pos[1], pos[2]))
        else
            self.file:write(string.format('M%f,%f ', pt[1], pt[2]))
            self.file:write(string.format('L%f,%f ', pos[1], pos[2]))
        end
    end

    self.lastpt[ind] = pos
    self.lastind = ind
    self.count = self.count + 1

    if self.count > self.breakpt then
        self.file:write(SVG_PATH_END)
        self.count = 0
    end
end

function SVGLinePlot:close()
    self.file:write(SVG_PATH_END)
    self.file:write(SVG_FOOTER)
    self.file:flush()
    self.file:close()
end

-- =================================================================
local LastPositionRecorder = util.class(Observer)
function LastPositionRecorder:init(filename)
    self.filename = filename
    self.pos = {}
end

function LastPositionRecorder:update_particle(particle)
    self.pos[particle.index] = particle.pos
end

-- =================================================================
local BounceCountRecorder = util.class(Observer)
function BounceCountRecorder:init(filename)
    self.filename = filename
    self.bounces = {}
end

function BounceCountRecorder:update_collision(particle, object, time)
    local i = particle.index
    if not self.bounces[i] then
        self.bounces[i] = 0
    end
    self.bounces[i] = self.bounces[i] + 1
end

-- =================================================================
local TimePrinter = util.class(Observer)
function TimePrinter:init(interval)
    self.interval = interval
end

function TimePrinter:begin()
    self.step = 0
end

function TimePrinter:update_time(p)
    if self.step % self.interval == 0 then
        print(self.step)
    end

    self.step = self.step + 1
end

function TimePrinter:close()
end

-- =================================================================
local ObserverGroup = util.class(Observer)
function ObserverGroup:init(observers)
    self.observers = observers
end

function ObserverGroup:begin()
    for i = 1, #self.observers do
        self.observers[i]:begin()
    end
end

function ObserverGroup:update_particle(particle)
    for i = 1, #self.observers do
        self.observers[i]:update_particle(particle)
    end
end

function ObserverGroup:update_time(time) 
    for i = 1, #self.observers do
        self.observers[i]:update_time(time)
    end
end

function ObserverGroup:update_collision(particle, object, time)
    for i = 1, #self.observers do
        self.observers[i]:update_collision(particle, object, time)
    end
end

function ObserverGroup:is_triggered()
    for i = 1, #self.observers do
        if self.observers[i]:is_triggered() then
            return true
        end
    end
    return false
end

function ObserverGroup:is_triggered_particle(particle)
    for i = 1, #self.observers do
        if self.observers[i]:is_triggered_particle(particle) then
            return true
        end
    end
    return false
end

function ObserverGroup:reset()
    for i = 1, #self.observers do
        self.observers[i]:reset()
    end
end

function ObserverGroup:close()
    for i = 1, #self.observers do
        self.observers[i]:close()
    end
end

return {
    Observer=Observer,
    ObserverGroup=ObserverGroup,
    StateFileRecorder=StateFileRecorder,
    ImageRecorder=ImageRecorder,
    LastPositionRecorder=LastPositionRecorder,
    PointImageRecorder=PointImageRecorder,
    TimePrinter=TimePrinter,
    SVGLinePlot=SVGLinePlot
}
