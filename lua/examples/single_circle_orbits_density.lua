local ics = require('plinko.ics')
local neighborlist = require('plinko.neighborlist')
local forces = require('plinko.forces')
local objects = require('plinko.objects')
local observers = require('plinko.observers')
local plotting = require('plinko.plotting')

local conf = {
    dt = 1e-4,
    eps = 1e-6,
    nbl = neighborlist.NaiveNeighborlist(),
    forces = {forces.force_gravity},
    particles = {objects.PointParticle({0.501, 0.85}, {0.3, 0}, {0, 0})},
    objects = {objects.Circle({0.5, 0.5}, 0.45)},
    observers = {
        observers.ImageRecorder('./test.img',
            plotting.DensityPlot(objects.Box({0, 0}, {1, 1}), 3000)
        ),
        observers.TimePrinter(1e6)
    },
}

local s = ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e6)
local t_end = os.clock()
print(t_end - t_start)
