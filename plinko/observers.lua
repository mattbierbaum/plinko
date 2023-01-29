local util = require('plinko.util')
local vector = require('plinko.vector')
local objects = require('plinko.objects')
local image = require('plinko.image')

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
function ImageRecorder:init(filename, plotter, format, toner)
    self.format = format or 'pgm5'
    self.filename = filename
    self.plotter = plotter
    self.lastposition = {}
    self.segment = objects.Segment({0,0}, {0,0})

    self.cmap = image.cmaps.gray_r
    self.norm = image.norms.eq_hist

    if toner ~= nil then
        self.cmap = toner.cmap ~= nil and toner.cmap or self.cmap
        self.norm = toner.norm ~= nil and toner.norm or self.norm
    end

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
        --self.plotter:draw_point(self.segment.p0)
        lastposition[1] = particle.pos[1]
        lastposition[2] = particle.pos[2]
    else
        self.lastposition[ind] = {particle.pos[1], particle.pos[2]}
    end
end

function ImageRecorder:update_collision(particle, object, time)

end

function ImageRecorder:reset()
    self.lastposition = {}
end

function ImageRecorder:tone()
    local n = self.norm(self.plotter:get_array())
    return self.cmap(n)
end

function ImageRecorder:save_csv(fn)
    local arr = self.plotter:get_array()
    arr:save_csv(fn)
end

function ImageRecorder:save_bin(fn)
    local arr = self.plotter:get_array()
    arr:save_bin(fn)
end

function ImageRecorder:save_pgm2(fn)
    self:tone():save_pgm2(fn)
end

function ImageRecorder:save_pgm5(fn)
    self:tone():save_pgm5(fn)
end

function ImageRecorder:save_ppm()
    self:tone():save_ppm(fn)
end

function ImageRecorder:close()
    if self.format == 'csv' then
        self:save_csv(self.filename)
    end
    if self.format == 'bin' then
        self:save_bin(self.filename)
    end
    if self.format == 'pgm5' then
        self:save_pgm5(self.filename)
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
local SVG_PATH_RAW_STR = 'd="'
local SVG_PATH_RAW_END = '"\n'
local SVG_FOOTER = '</g></svg>'

function SVGLinePlot:init(filename, box, lw, opacity, crosspath)
    self.filename = filename
    self.box = box
    self.lw = lw
    self.opacity = opacity ~= nil and opacity or 1.0
    self.crosspath = crosspath ~= nil and crosspath or false
    self.lastpt = {}
    self.lastind = -1
    self.breakpt = 10000
    self.y0 = self.box.ll[2]
    self.y1 = self.box.uu[2]
    self.PATH_START = SVG_PATH_STR
    self.PATH_END = SVG_PATH_END
    self.HEADER = SVG_HEADER
    self.FOOTER = SVG_FOOTER
end

function SVGLinePlot:begin()
    self.count = 0
    self.file = io.open(self.filename, 'w')
    self:write(
        string.format(
            self.HEADER,
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

function SVGLinePlot:write(str)
    self.file:write(str)
end

function SVGLinePlot:update_particle(particle)
    local ind = particle.index
    local pos = self:reflect(particle.pos)

    local lind = self.lastind
    local lpos = self.lastpt[ind]
    local pt = lpos and lpos or pos

    if self.count == 0 then
        self:write(string.format(self.PATH_START, self.lw, self.opacity))
        self:write(string.format('M%f,%f ', pt[1], pt[2]))
    else
        if self.crosspath or (lind == ind) then
            self:write(string.format('L%f,%f ', pos[1], pos[2]))
        else
            self:write(string.format('M%f,%f ', pt[1], pt[2]))
            self:write(string.format('L%f,%f ', pos[1], pos[2]))
        end
    end

    self.lastpt[ind] = pos
    self.lastind = ind
    self.count = self.count + 1

    if self.count > self.breakpt then
        self:write(self.PATH_END)
        self.count = 0
    end
end

function SVGLinePlot:close()
    self:write(self.PATH_END)
    self:write(self.FOOTER)
    self.file:flush()
    self.file:close()
end

-- =================================================================
local SVGPathPrinter = util.class(SVGLinePlot)
function SVGPathPrinter:init(...)
    SVGLinePlot.init(self, '', ...)
    self.PATH_START = SVG_PATH_RAW_STR
    self.PATH_END = SVG_PATH_RAW_END
end

function SVGPathPrinter:begin()
    self.count = 0
end

function SVGPathPrinter:write(str)
    io.write(str)
end

function SVGPathPrinter:close()
    self:write(self.PATH_END)
end

-- =================================================================
local InitialStateRecorder = util.class(Observer)
function InitialStateRecorder:init(filename)
    self.filename = filename
    self.particle = {}
    self.recorded = {}
end

function InitialStateRecorder:update_particle(particle)
    local i = particle.index
    if not self.recorded[i] then
        self.particle[i] = objects.PointParticle(particle.pos, particle.vel, particle.acc)
        self.recorded[i] = true
    end
end

function InitialStateRecorder:close()
    local file = io.open(self.filename, 'w')

    for i = 1, #self.particles do
        pos = self.particle[i].pos
        vel = self.particle[i].vel
        acc = self.particle[i].acc
        file:write(
            string.format('%f %f %f %f %f %f\n',
                pos[1], pos[2], vel[1], vel[2], acc[1], acc[2]
            )
        )
    end

    file:flush()
    file:close()
end

-- =================================================================
local LastStateRecorder = util.class(Observer)
function LastStateRecorder:init(filename)
    self.filename = filename
    self.particle = {}
end

function LastStateRecorder:update_particle(particle)
    self.particle[particle.index] = objects.PointParticle(particle.pos, particle.vel, particle.acc)
end

function InitialStateRecorder:close()
    local file = io.open(self.filename, 'w')

    for i = 1, #self.particles do
        pos = self.particle[i].pos
        vel = self.particle[i].vel
        acc = self.particle[i].acc
        file:write(
            string.format('%f %f %f %f %f %f\n',
                pos[1], pos[2], vel[1], vel[2], acc[1], acc[2]
            )
        )
    end

    file:flush()
    file:close()
end

-- =================================================================
local LastCollisionRecorder = util.class(Observer)
function LastCollisionRecorder:init(filename)
    self.filename = filename
    self.object_index = {}
end

function LastCollisionRecorder:update_collision(particle, object, time)
    local i = particle.index
    self.object_index[i] = object.obj_index
end

function LastCollisionRecorder:close()
    local file = io.open(self.filename, 'w')
    for i = 1, #self.object_index do
        file:write(
            string.format('%d\n', self.object_index[i])
        )
    end
    file:flush()
    file:close()
end

-- =================================================================
local CollisionCountRecorder = util.class(Observer)
function CollisionCountRecorder:init(filename)
    self.filename = filename
    self.bounces = {}
end

function CollisionCountRecorder:update_collision(particle, object, time)
    local i = particle.index
    if not self.bounces[i] then
        self.bounces[i] = 0
    end
    self.bounces[i] = self.bounces[i] + 1
end

function CollisionCountRecorder:close()
    local file = io.open(self.filename, 'w')
    for i = 1, #self.bounces do
        file:write(
            string.format('%d\n', self.bounces[i])
        )
    end
    file:flush()
    file:close()
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
    InitialStateRecorder=InitialStateRecorder,
    LastStateRecorder=LastStateRecorder,
    LastCollisionRecorder=LastCollisionRecorder,
    CollisionCountRecorder=CollisionCountRecorder,
    PointImageRecorder=PointImageRecorder,
    TimePrinter=TimePrinter,
    SVGLinePlot=SVGLinePlot,
    SVGPathPrinter=SVGPathPrinter
}
