local P = require('plinko')

local conf = {
    dt = 1e-3,
    eps = 1e-6,
    nbl = P.neighborlist.CellNeighborlist(P.objects.Box({0, 0}, {1, 1}), {100, 100}),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({0.501, 0.85}, {0.3, 0}, {0, 0})},
    objects = {
        P.objects.Box({0, 0}, {1, 1}),
        P.objects.Box({.1, .1}, {.2, .2})
    },
    observers = {
        --observers.TimePrinter(1e6)
    },
}

local s = P.ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e6)
local t_end = os.clock()
print(t_end - t_start)
