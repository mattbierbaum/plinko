local P = require('plinko')

local N = 100
local O = 8
local rad = 0.577255
local damp = 1.0

math.randomseed(100)
function rotated_octagon(pos, rad)
    return P.ics.obj_funcs.ngon(pos, rad, 4, {damp=damp}):rotate(math.random()*math.pi*2)
end

local obj, bd = P.ics.hex_grid_object(O, 2*O, rotated_octagon, rad)
local max = math.max(bd[1], bd[2]*1.3)
local box0 = P.objects.Box({0, 0}, bd)
local box1 = P.objects.Box({0, 0}, {bd[1], bd[2]*1.3})
local box2 = P.objects.Box({0, 0}, {max, max})
obj[#obj + 1] = box0

local h = bd[2]
local w = bd[1]

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    nbl = P.neighborlist.CellNeighborlist(box1, {200, 200}, 1e-1),
    forces = {P.forces.force_gravity},
    particles = {
        P.objects.SingleParticle({w/2, h-0.5}, {0.1, 0}, {0, 0}),
    },
    objects = obj,
    observers = {
        P.observers.StateFileRecorder('./test.csv'),
        P.observers.TimePrinter(1e6),
        P.interrupts.Collision(box0.segments[4])
    },
}

local s = P.ics.create_simulation(conf)
s:step(5e6)