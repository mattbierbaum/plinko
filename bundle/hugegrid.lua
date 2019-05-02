local P = require('plinko')

local argparse = require('lib.argparse')
local opt = argparse(){name='hugegrid'}
opt:option('-g', 'Fractional gap between circles', 1e-3, tonumber):argname('gap')
opt:option('-d', 'Collision damping constant', 1.0, tonumber):argname('damp')
opt:option('-N', 'Number of rows', 100, tonumber):argname('N')
opt:option('-o', 'Type of output (svg, csv, pgm)', 'svg'):argname('filetype')
opt:option('-p', 'If type pgm, the number of pixels wide.', 1080, tonumber):argname('pix')
opt:argument('filename', 'Filename for output'):args('?')
local arg = opt:parse(arg)

local O = arg.N
local rad = 0.5*(1 - arg.g)
local cargs = {damp=arg.d}

local obj, bd = P.ics.hex_grid_object(O, 2*O, P.ics.obj_funcs.circle, rad)
local w, h = bd[1], bd[2]
local box = P.objects.Box({0, 0}, {w, h*1.1})
obj[#obj + 1] = box

local filename = (arg.filename or 'hugegrid') .. '.' .. arg.o
local observers = {
    svg = P.observers.SVGLinePlot(filename, box, 1e-5),
    csv = P.observers.StateFileRecorder(filename),
    pgm = P.observers.ImageRecorder(
        filename, P.plotting.DensityPlot(box, arg.p/w), 'pgm5'
    )
}

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    nbl = P.neighborlist.CellNeighborlist(box, {50, 50}, 1e-1),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({w/2, h-0.5}, {0.1, 0}, {0, 0})},
    objects = obj,
    observers = {
        observers[arg.o],
        P.observers.TimePrinter(1e6),
        P.interrupts.Collision(box.segments[4])
    },
}

P.ics.create_simulation(conf):run()
