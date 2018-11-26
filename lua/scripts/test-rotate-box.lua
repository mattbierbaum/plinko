local ics = require('ics')
local neighborlist = require('neighborlist')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')
local util = require('util')

local conf = {
    dt = 1e-3,
    eps = 1e-2,
    forces = {forces.force_gravity},
    particles = {objects.PointParticle({0.901, 0.95}, {0.2, 0.1}, {0, 0})},
    objects = {objects.Box(), objects.Box({0.3, 0.1}):translate({0.2, 0.2}):rotate(math.pi/3):scale(0.1)},
    observers = {
        observers.StateFileRecorder('./test.csv'),
        observers.TimePrinter(1e6)
    },
}

util.tprint(conf.objects)

local s = ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e6)
local t_end = os.clock()
print(t_end - t_start)
