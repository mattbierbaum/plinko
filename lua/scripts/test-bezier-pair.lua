local ics = require('ics')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')
local util = require('util')

local conf = {
    dt = 1e-3,
    eps = 1e-5,
    forces = {forces.force_central_invert},
    objects = {
        objects.BezierCurve({{0, 0}, {0, 1.5}, {1, 0}, {1, 1}}),
        objects.BezierCurve({{0, 0}, {0, 1}, {1, -0.5}, {1, 1}}),
    }
}

conf.particles = {objects.SingleParticle({0.61, 0.51}, {0.01, 0.011}, {0, 0})}
conf.observers = {observers.StateFileRecorder('./test.csv')}

local s = ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e6)
local t_end = os.clock()
print(t_end - t_start)

--[[conf.forces = {forces.force_central}
conf.particles = {objects.SingleParticle({1.51, 1.21}, {0.01, 0.211}, {0, 0})}
conf.observers = {observers.StateFileRecorder('./test2.csv')}

local s = ics.create_simulation(conf)
local t_start = os.clock()
s:step(1.6e7)
local t_end = os.clock()
print(t_end - t_start)]]
