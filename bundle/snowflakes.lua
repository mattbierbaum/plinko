local P = require('plinko')

local argparse = require('lib.argparse')
local opt = argparse(){name='curtains'}
opt:option('-g', 'Circle slit size (6 per circle)', 2e-3, tonumber):argname('gap')
opt:option('-r', 'Circle radii (lattice spacing is 0.5)', 0.5001, tonumber):argname('rad')
opt:option('-d', 'Collision damping constant', 1.0, tonumber):argname('damp')
opt:option('-N', 'Number of rows', 20, tonumber):argname('N')
opt:option('-o', 'Type of output (svg, csv, pgm)', 'svg'):argname('filetype')
opt:option('-L', 'If type pgm, the number of pixels wide.', 1080, tonumber):argname('pix')
opt:argument('filename', 'Filename for output', 'snowflakes'):args('?')
local arg = opt:parse(arg)

local O = arg.N
local rad = arg.r
local cargs = {damp=arg.d}

function masked_circle(p, r, N, eps, offset)
    return P.objects.MaskedCircle(p, r,
        P.objects.circle_masks.circle_nholes(N, eps, offset),
        cargs
    )
end

local obj, bd = P.ics.hex_grid_object(O, O, masked_circle, rad, 6, arg.g, 0)
local w, h = bd[1], bd[2]
local box = P.objects.Box({0, 0}, {w, h*1.3})
obj[#obj + 1] = box

local filename = (arg.filename or 'snowflakes') .. '.' .. arg.o
local observers = {
    svg = P.observers.SVGLinePlot(filename, box, 1e-5),
    csv = P.observers.StateFileRecorder(filename),
    pgm = P.observers.ImageRecorder(
        filename, P.plotting.DensityPlot(box, arg.p/w), 'pgm5'
    )
}

local fx = 0.49473684210526
local fy = 0.92925900469569

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    nbl = P.neighborlist.CellNeighborlist(box, {200, 200}, 1e-1),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({fx*w, fy*h}, {0.0, 0}, {0, 0})},
    objects = obj,
    observers = {
        observers[arg.o],
        P.observers.TimePrinter(1e5),
        P.interrupts.Collision(box.segments[4])
    },
}

local s = P.ics.create_simulation(conf)
s:step(1e6)
