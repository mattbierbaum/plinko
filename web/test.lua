package.path = '../lua/?.lua;./web/?.lua' .. package.path
print(package.path)

local js = require('js')

local ics = require('ics')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')
local util = require('util')

local window = js.global
local paper = window.paper

PaperObserver = util.class(observers.Observer)
function PaperObserver:init(w, h)
    self.w = w
    self.h = h
    self.lastposition = nil
    self.segment = objects.Segment({0, 0}, {1, 1})
end

function PaperObserver:begin()
    self.lastposition = nil
    self.path = js.new(paper.Path)
    self.path.strokeColor = 'black'
end

function PaperObserver:update_particle(particle)
    if self.lastposition then
        self.segment.p0[1] = self.lastposition[1]
        self.segment.p0[2] = self.lastposition[2]
        self.segment.p1[1] = particle.pos[1]
        self.segment.p1[2] = particle.pos[2]

        --local path = js.new(paper.Path)
        --path.strokeColor = 'black'
        --local p0 = js.new(paper.Point, self.segment.p0[1], self.segment.p0[2])
        local p1 = js.new(paper.Point, self.segment.p1[1], self.h - self.segment.p1[2])
        --path:moveTo(p0)
        self.path:lineTo(p1)

        self.lastposition[1] = particle.pos[1]
        self.lastposition[2] = particle.pos[2]
    else
        self.lastposition = {particle.pos[1], particle.pos[2]}
        local p0 = js.new(paper.Point, self.lastposition[1], self.h - self.lastposition[2])
        self.path:moveTo(p0)
    end
end

function create_sim(w, h)
    local conf = {
        dt = 1e-1,
        eps = 1e-4,
        forces = {forces.force_gravity},
        particles = {objects.SingleParticle({0.51*w, 0.91*h}, {0.01, 0.211*h}, {0, 0})},
        objects = {
            objects.Box({0, 0}, {w, h}),
            objects.BezierCurve({
                {0, 0}, {0, h}, {w, h}, {w, 0}
            })
        },
        observers = {PaperObserver(w, h)},
    }
    
    local s = ics.create_simulation(conf)
    return s
end

window.onload = function()
    paper:setup('canvas')
    local view = paper:getView()
    local w, h = view.bounds.width, view.bounds.height
    local s = create_sim(w, h)

    local t_start = os.clock()
    s:step(1e4)
    local t_end = os.clock()
    print(t_end - t_start)
end

function setup_drawing()
    local path = nil
    local path = js.new(paper.Path)
    path.strokeColor = 'black'
    
    local p0 = js.new(paper.Point, 100, 100)
    local p1 = js.new(paper.Point, 50, 50)
    path:moveTo(p0)
    path:lineTo(p1)

    local tpath = nil
    local tool = js.new(paper.Tool)
    tool.onMouseDown = function(event)
        tpath = js.new(paper.Path)
        tpath.strokeColor = 'black'
        tpath:add(js.new(paper.Point, window.event.x, window.event.y))
    end

    tool.onMouseDrag = function(event)
        tpath:add(js.new(paper.Point, window.event.x, window.event.y))
    end
end

function interop()
    print('hi')
end

window.interop = interop
