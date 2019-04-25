local P = require('plinko')

local O = 8
local rad = 0.4995

function hemisphere(p)
    return P.objects.MaskedCircle(p, rad,
        P.objects.circle_masks.circle_angle_range(math.pi, 2*math.pi)
    )
end

local obj, bd = P.ics.hex_grid_object(O, O, hemisphere)
local w, h = bd[1], bd[2]
local view = {bd[1], bd[2]*1.3}

local box0 = P.objects.Box({0, 0}, view)
local box1 = P.objects.Box({0, 0}, view)
local box2 = P.objects.Box({0, 0}, view)
obj[#obj + 1] = box0

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    nbl = P.neighborlist.CellNeighborlist(box1, {200, 200}, 1e-1),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({w/2, h-0.5}, {0.1, 0}, {0, 0})},
    objects = obj,
    observers = {
        P.observers.StateFileRecorder('./test.csv'),
        P.observers.TimePrinter(1e6),
        P.interrupts.Collision(box0.segments[4])
    },
}

local s = P.ics.create_simulation(conf)
s:step(1e10)
