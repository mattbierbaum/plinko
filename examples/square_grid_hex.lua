local P = require('plinko')

local O = 20
local rad = 0.4995
local cargs = {damp=1.0}--0.999}

--local obj, bd = ics.square_grid_object(O, 2*O, ics.obj_funcs.circle, rad)
local obj, bd = P.ics.square_grid_object(O, 2*O, P.ics.obj_funcs.ngon, rad, 6, cargs)
local w, h = bd[1], bd[2]
local view = {bd[1], bd[2]*1.3}
local max = math.max(view[1], view[2])

local box0 = P.objects.Box({0, 0}, bd)
local box1 = P.objects.Box({0, 0}, bd)
local box2 = P.objects.Box({0, 0}, {max, max})
obj[#obj + 1] = box0

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    nbl = P.neighborlist.CellNeighborlist(box1, {100, 100}, 1.33e-1),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({w/2+0.0, O+0.98}, {0.1, 0}, {0, 0})},
    objects = obj,
    observers = {
        P.observers.StateFileRecorder('./test.csv'),
        P.observers.TimePrinter(1e6),
        P.interrupts.Collision(box0.segments[4])
    },
}

local s = P.ics.create_simulation(conf)
s:step(1e7)
