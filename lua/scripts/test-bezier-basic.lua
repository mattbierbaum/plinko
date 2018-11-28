local ics = require('ics')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')
local util = require('util')

local conf = {
    dt = 1e-3,
    eps = 1e-6,
    forces = {forces.force_gravity},
    particles = {objects.SingleParticle({0.51, 0.91}, {0.01, 0.211}, {0, 0})},
    objects = {
        objects.Box({0, 0}, {1, 1}),
        objects.BezierCurve({
            {0, 0}, {0, 1}, {1, 1}, {1, 0}
        })
    },
    observers = {
        observers.StateFileRecorder('./test.csv'),
        observers.TimePrinter(1e6)
    },
}

local s = ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e6)
local t_end = os.clock()
print(t_end - t_start)
