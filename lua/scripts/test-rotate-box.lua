local ics = require('ics')
local neighborlist = require('neighborlist')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')
local util = require('util')
local plotting_image = require('plotting_image')

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    forces = {forces.force_gravity},
    particles = {objects.SingleParticle({0.901, 0.95}, {-0.2, -0.1}, {0, 0})},
    objects = {
        objects.Box({0, 0}, {1, 1}),
        objects.Rectangle({0, 0}, {0.4, 0.2})
            :translate({0.2, 0.2})
            :rotate(math.pi/3)
            :scale(0.5),
        objects.RegularPolygon(6, {0.2, 0.1}, 0.1)
    },
    observers = {
        observers.StateFileRecorder('./test.csv'),
        observers.SVGLinePlot('./test.svg', objects.Box({0,0}, {1,1}), 2e-5),
        observers.TimePrinter(1e6),
        observers.ImageRecorder('./test.pgm',
            plotting_image.DensityPlot(objects.Box({0,0}, {1,1}), 1080), 'pgm5'
        ),
        observers.ImageRecorder('./test.bin',
            plotting_image.DensityPlot(objects.Box({0,0}, {1,1}), 1080), 'bin'
        ),
    },
}

util.tprint(conf.objects)

local s = ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e5)
local t_end = os.clock()
print(t_end - t_start)
