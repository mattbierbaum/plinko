local ics = require('ics')
local neighborlist = require('neighborlist')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')

function concentric_circles(N, minr, eps)
    local p = {0.5, 0.5}
    local dr = (0.5 - minr) / N
    local objs = {
        objects.Box({0, 0}, {1, 1}),
        objects.Circle(p, 0.49)
    }

    for i = 1, N do
        local r = 0.5 - dr * i
        objs[#objs + 1] = objects.MaskedCircle(p, r,
            objects.circle_nholes(4, eps, math.pi/4 * (i % 2))
        )
    end

    return objs
end

local conf = {
    dt = 1e-3,
    eps = 1e-6,
    nbl = neighborlist.CellNeighborlist(
        objects.Box({0, 0}, {1, 1}), {100, 100}
    ),
    forces = {forces.force_gravity},
    particles = {objects.PointParticle({0.501, 0.85}, {0.3, 0}, {0, 0})},
    objects = concentric_circles(8, 0.38, 1e-3),
    observers = {
        observers.StateFileRecorder('./test.csv'),
        observers.TimePrinter(1e6)
    },
}

local s = ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e7)
local t_end = os.clock()
print(t_end - t_start)
