local P = require('plinko')
local argparse = require('lib.argparse')

local opt = argparse(){name='curtains'}
opt:option('-g', 'Fractional gap between circles.', 1e-3, tonumber):argname('gap')
opt:option('-d', 'Collision damping constant', 1.0, tonumber):argname('damp')
opt:option('-N', 'Number of rows', 8, tonumber):argname('N')
opt:option('-o', 'Type of output (svg, csv, pgm)', 'svg'):argname('filetype')
opt:option('-p', 'If type pgm, the number of pixels wide.', 1080, tonumber):argname('pix')
opt:argument('filename', 'Filename for output', 'curtains'):args('?')
local arg = opt:parse(arg)
local fn = arg.filename or 'hearrt.svg'

local O = arg.N
local rad = 0.5*(1 - arg.g)
local cargs = {damp=arg.d}

function hemisphere(p)
    return P.objects.MaskedCircle(p, rad,
        P.objects.circle_masks.circle_angle_range(math.pi, 2*math.pi), cargs
    )
end

local obj, bd = P.ics.hex_grid_object(O, O, hemisphere)
local w, h = bd[1], bd[2]
local box = P.objects.Box({0, 0}, {w, h*1.3})
obj[#obj + 1] = box

if arg.o ~= 'svg' and arg.o ~= 'csv' and arg.o ~= 'pgm' then
    print('Output filetype must be one of [svg, csv, pgm]')
    os.exit()
end

local filename = (arg.filename or 'curtains') .. '.' .. arg.o
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
    nbl = P.neighborlist.CellNeighborlist(box, {200, 200}, 1e-1),
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
