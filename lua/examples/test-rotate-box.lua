local P = require('plinko')

local box = P.objects.Box({0, 0}, {1, 1})

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({0.901, 0.95}, {-0.2, -0.1}, {0, 0})},
    objects = {
        P.objects.Box({0, 0}, {1, 1}),
        P.objects.Rectangle({0, 0}, {0.4, 0.2})
            :translate({0.2, 0.2})
            :rotate(math.pi/3)
            :scale(0.5),
        P.objects.RegularPolygon(6, {0.2, 0.1}, 0.1)
    },
    observers = {
        P.observers.StateFileRecorder('./test.csv'),
        P.observers.SVGLinePlot('./test.svg', box, 2e-5),
        P.observers.TimePrinter(1e6),
        P.observers.ImageRecorder('./test.pgm', P.plotting.DensityPlot(box, 1080), 'pgm5'),
        P.observers.ImageRecorder('./test.bin', P.plotting.DensityPlot(box, 1080), 'bin')
    },
}

local s = P.ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e5)
local t_end = os.clock()
print(t_end - t_start)
