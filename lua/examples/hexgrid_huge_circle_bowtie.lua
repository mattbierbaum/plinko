local P = require('plinko')
local argparse = require('lib.argparse')

local O = 100
local rad = 0.4995
local opt = argparse(){name='bowtie'}
P.cli.options_observer(opt, 'bowtie.csv', '4e4')
local arg = opt:parse(arg)

local obj, bd = P.ics.hex_grid_object(O, 2*O, P.ics.obj_funcs.circle, rad)
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
    nbl = P.neighborlist.CellNeighborlist(box1, {50, 50}, 1e-1),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({w/2, h-0.5}, {0.1, 0}, {0, 0})},
    objects = obj,
    observers = {
        P.cli.args_to_observer(arg, box2),
        P.observers.TimePrinter(1e6),
        P.interrupts.Collision(box0.segments[4])
    },
}

local s = P.ics.create_simulation(conf)
s:step(1e7)