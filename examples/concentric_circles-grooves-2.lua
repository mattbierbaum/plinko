local P = require('plinko')

function concentric_circles(N, minr, eps)
    local p = {0.5, 0.5}
    local dr = (0.5 - minr) / N
    local objs = {
        P.objects.Box({0, 0}, {1, 1}),
        P.objects.Circle(p, 0.5)
    }

    for i = 1, N do
        local r = 0.5 - dr * i
        objs[#objs + 1] = P.objects.MaskedCircle(p, r,
            P.objects.circle_masks.circle_nholes(6, eps, math.pi/4 * (i % 2))
        )
    end

    return objs
end

local box = P.objects.Box({0, 0}, {1, 1})
local conf = {
    dt = 1e-3,
    eps = 1e-6,
    nbl = P.neighborlist.CellNeighborlist(box, {200, 200}, 1e-1),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({0.500, 0.986}, {0.1, 0}, {0, 0})},
    objects = concentric_circles(50, 0.26, 5e-4),
    observers = {
        P.observers.ImageRecorder('./test.pgm', 
            P.plotting.DensityPlot(box, 10000), 'pgm5'
        ),
        P.observers.TimePrinter(1e6)
    },
}

local s = P.ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e8)
local t_end = os.clock()
print(t_end - t_start)
