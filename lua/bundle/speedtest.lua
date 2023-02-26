local P = require('plinko')

local conf = {
    dt = 1e-2,
    eps = 1e-6,
    nbl = P.neighborlist.NaiveNeighborlist(), --P.neighborlist.CellNeighborlist(P.objects.Box({0, 0}, {1, 1}), {100, 100}),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({0.501, 0.85}, {0.3, 0}, {0, 0})},
    objects = {P.objects.Box({0, 0}, {1, 1})},
    observers = {},
}

local steps = 1e6
local s = P.ics.create_simulation(conf)
local t_start = os.clock()
s:step(steps)
local t_end = os.clock()
local time = t_end - t_start
local out = string.format(
    '%0.2f million steps per second (%0.2f seconds)',
    (steps / time / 1e6), time
)
print(out)
