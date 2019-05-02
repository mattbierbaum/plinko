local P = require('plinko')

local O = {3, 10}
local N = 10000
local rad = 0.4
local cargs = {damp=0.8}

local obj, bd = P.ics.hex_grid_object(O[1], O[2], P.ics.obj_funcs.circle, rad, cargs)
local w, h = bd[1], bd[2]

local box0 = P.objects.Box({0, 0}, bd)
local box1 = P.objects.Box({0, 0}, bd)
local box2 = P.objects.Box({0, 0}, bd)
obj[#obj + 1] = box0

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    nbl = P.neighborlist.CellNeighborlist(box1, {200, 200}, 1e-1),
    forces = {P.forces.force_gravity},
    particles = {
        P.objects.UniformParticles(
            {w/2-0.1, h-0.5}, {w/2+0.1, h-0.5},
            {-0.1, 0.0}, {0.1, 0.0}, N
        )
    },
    objects = obj,
    observers = {
        P.observers.ImageRecorder('./test.img',
            P.plotting.DensityPlot(box2, 4500/(box2.uu[1] - box2.ll[1]) )
        ),
        P.observers.TimePrinter(1e4),
        P.interrupts.Collision(box0.segments[4])
    },
}

local s = P.ics.create_simulation(conf)
s:step(3e5)
