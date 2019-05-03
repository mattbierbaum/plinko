local P = require('plinko')

local argparse = require('lib.argparse')
local opt = argparse(){name='plinko'}
opt:option('-g', 'Fractional gap between circles', 0.2, tonumber):argname('gap')
opt:option('-L', 'Lattice dimensions %i,%i', {3, 8}, P.util.tovec):argname('latt')
opt:option('-d', 'Collision damping constant', 0.8, tonumber):argname('damp')
opt:argument('filename', 'Filename for output', 'plinko.svg'):args('?')
local arg = opt:parse(arg)

local fn = arg.filename or 'plinko.svg'
local O = arg.L
local N = arg.N
local rad = 0.5 * (1 - arg.g)
local cargs = {damp=arg.d}

local obj, bd = P.ics.hex_grid_object(O[1], O[2], P.ics.obj_funcs.circle, rad, cargs)
local w, h = bd[1], bd[2]
local box = P.objects.Box({0, 0}, bd)
obj[#obj + 1] = box

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    nbl = P.neighborlist.CellNeighborlist(box, {200, 200}, 1e-1),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({w/2-0.05, h-0.5}, {-0.01, 0.0})},
    objects = obj,
    observers = {
        P.observers.SVGLinePlot(fn, box, 1e-5),
        --P.plotting.DensityPlot(box, 4500/w, 'pgm5')),
        P.observers.TimePrinter(1e4),
        P.interrupts.Collision(box.segments[4])
    },
}

local s = P.ics.create_simulation(conf)
s:step(3e5)
