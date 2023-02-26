local P = require('plinko')

function concentric_circles(N, minr, eps)
    local p = {0.5, 0.5}
    local dr = (0.5 - minr) / N
    local objs = {
        P.objects.Box({0, 0}, {1, 1}),
        P.objects.Circle(p, 0.49)
    }

    for i = 1, N do
        local r = 0.5 - dr * i
        objs[#objs + 1] = P.objects.MaskedCircle(p, r,
            P.objects.circle_masks.circle_nholes(4, eps, math.pi/4 * (i % 2))
        )
    end

    return objs
end

local conf = {
    dt = 1e-3,
    eps = 1e-6,
    nbl = P.neighborlist.CellNeighborlist(
        P.objects.Box({0, 0}, {1, 1}), {100, 100}
    ),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({0.501, 0.85}, {0.3, 0}, {0, 0})},
    objects = concentric_circles(8, 0.38, 1e-3),
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
