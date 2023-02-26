local P = require('plinko')

local conf = {
    dt = 1e-3,
    eps = 1e-7,
    nbl = P.neighborlist.CellNeighborlist(P.objects.Box({0,0}, {1,1}), {100, 100}),
    forces = {P.forces.generate_force_central({0.5, 0.5}, 1.0)},
    particles = {P.objects.SingleParticle({0.71, 0.6}, {0.1, 0}, {0, 0})},
    objects = {
        P.objects.Circle({0.3, 0.5}, 0.25),
        P.objects.Circle({0.6, 0.5}, 0.025),
        P.objects.Circle({0.58, 0.42}, 0.010),
        P.objects.Circle({0.58, 0.58}, 0.010)
    },
    observers = {
        P.observers.StateFileRecorder('./test.csv'),
        P.observers.TimePrinter(1e6)
    },
}

local s = P.ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e7)
local t_end = os.clock()
print(t_end - t_start)
