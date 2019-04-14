local ics = require('ics')
local neighborlist = require('neighborlist')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')

local conf = {
    dt = 1e-3,
    eps = 1e-7,
    nbl = neighborlist.CellNeighborlist(objects.Box({0,0}, {1,1}), {100, 100}),
    forces = {forces.force_central},
    particles = {objects.SingleParticle({0.71, 0.6}, {0.1, 0}, {0, 0})},
    objects = {
        objects.Circle({0.3, 0.5}, 0.25),
        objects.Circle({0.6, 0.5}, 0.025),
        objects.Circle({0.58, 0.42}, 0.010),
        objects.Circle({0.58, 0.58}, 0.010)
    },
    observers = {
        observers.StateFileRecorder('./test.csv'),
        observers.TimePrinter(1e6)
    },
}

local s = ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e7)
local t_end = os.clock()
print(t_end - t_start)
