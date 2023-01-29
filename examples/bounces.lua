local P = require('plinko')

local argparse = require('lib.argparse')
local opt = argparse(){name='plinko'}
opt:option('-g', 'Fractional gap between circles', '0.5', tonumber):argname('gap')
opt:option('-L', 'Lattice dimensions %i,%i', '2,3', P.util.tovec):argname('latt')
opt:option('-d', 'Collision damping constant', '0.8', tonumber):argname('damp')
P.cli.options_particles(opt, {-0.1, -0.1}, nil, {0.1, 0.1}, nil, 'uniform2d')
P.cli.options_seed(opt, '10')
P.cli.options_observer(opt, 'bounces.collisions', '4000')
local arg = opt:parse(arg)

local O = arg.L
local N = arg.Nv
local rad = 0.5 * (1 - arg.g)
local cargs = {damp=arg.d}

local obj, bd = P.ics.hex_grid_object(O[1], O[2], P.ics.obj_funcs.circle, rad, cargs)
local w, h = bd[1], bd[2]
local box = P.objects.Box({0, 0}, bd)
obj[#obj + 1] = box

local conf = {
    dt = 1e-2,
    eps = 1e-8,
    nbl = P.neighborlist.CellNeighborlist(box, {200, 200}, 1e-1),
    forces = {P.forces.force_gravity},
    particles = {P.cli.args_to_particles(arg, {w/2+0.001, h-0.5})},
    objects = obj,
    observers = {
        P.cli.args_to_observer(arg, box),
        P.observers.TimePrinter(1e3),
        P.interrupts.Collision(box.segments[4]),
        P.observers.InitialStateRecorder('bounces.p0')
    },
}

local s = P.ics.create_simulation(conf)
s:step(10000)
