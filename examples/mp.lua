local ics = require('ics')
local neighborlist = require('neighborlist')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')
local plotting_image = require('plotting_image')

local conf = {
    dt = 1e-4,
    eps = 1e-6,
    nbl = neighborlist.NaiveNeighborlist(),
    forces = {forces.force_gravity},
    particles = {objects.UniformParticles(
        {0.501, 0.85}, {0.51, 0.86}, {0, 0}, {0, 0}, 20
    )},
    objects = {objects.Circle({0.5, 0.5}, 0.45)},
    observers = {
        --observers.ImageRecorder('./test.img',
        --    plotting_image.DensityPlot(objects.Box({0, 0}, {1, 1}), 3000)
        --),
        --observers.TimePrinter(1e6)
    },
}

local s = ics.create_simulation(conf)
local q, th = s:parallelize(4)
local t_start = os.clock()
q(1e6)
q(-1)
for i = 1, #th do
    th[i]:join()
end
local t_end = os.clock()
print(t_end - t_start)
