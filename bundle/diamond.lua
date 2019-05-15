local P = require('plinko')
local argparse = require('lib.argparse')

local opt = argparse(){name='diamond'}
opt:option('-g', 'Fractional gap between squares.', 0.05, tonumber):argname('gap')
opt:option('-d', 'Collision damping constant', 1.0, tonumber):argname('damp')
P.cli.options_seed(opt, '10')
P.cli.options_observer(opt, 'diamond.svg', '1e2')
local arg = opt:parse(arg)

local O = 20
local rad = (1 - arg.g) * 0.5
local cargs = {damp=arg.d}

local obj, bd = P.ics.square_grid_object(O, 2*O, P.ics.obj_funcs.ngon, rad, 4, cargs)
local w, h = bd[1], bd[2]
local view = {w, h*1.3}

local box = P.objects.Box({0, 0}, bd)
obj[#obj + 1] = box

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    nbl = P.neighborlist.CellNeighborlist(box, {100, 100}, 1.33e-1),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({w/2+0.3, O+0.98}, {0.1, 0}, {0, 0})},
    objects = obj,
    observers = {
        P.cli.args_to_observer(arg, box),
        P.observers.TimePrinter(1e6),
        P.interrupts.Collision(box.segments[4])
    },
}

P.ics.create_simulation(conf):run()
