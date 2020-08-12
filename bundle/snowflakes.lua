local P = require('plinko')

local argparse = require('lib.argparse')
local opt = argparse(){
    name='curtains',
    epilog=[[
Suggestions:

snowflakes -g 1e-2 -R 0.501 -d 0.9999 -N 20 -o snowflakes.pgm -r 4e3
snowflakes -g 1.5e-3 -R 0.50001 -N 20,20 -d 0.99997 -v 0.00019,0 -r 4e3
snowflakes -g 1.2e-3 -R 0.50001 -N 20,30 -d 0.99998 -v 0.00019,0 -r 4e3
           -p 0.5123,0.901
]]}
opt:option('-g', 'Circle slit size as fraction of circumference', '1e-4', tonumber):argname('gap')
opt:option('-G', 'Number of slits per circle', '6', tonumber):argname('slits')
opt:option('--offset', 'Hole placement offset in fractions of a circle', '0.25', tonumber)
opt:option('-R', 'Circle radii, lattice spacing is 0.5', '0.50001', tonumber):argname('rad')
opt:option('-d', 'Collision damping constant', '1.0', tonumber):argname('damp')
opt:option('-t', 'Max time', '1e7', tonumber):argname('maxt')
opt:option('-N', 'Number of rows, columns "%i,%i"', '14,20', P.util.tovec):argname('N0')
opt:option('-p', 'Fractional starting position "%f,%f"', '0.501,0.90', P.util.tovec):argname('p0')
opt:option('-v', 'Fractional starting velocity "%f,%f"', '1e-3,0.0', P.util.tovec):argname('v0')
P.cli.options_seed(opt, '10')
P.cli.options_observer(opt, 'snowflakes.pgm', '3e3')
local arg = opt:parse(arg)

local Ox, Oy = arg.N[1], arg.N[2]
local rad = arg.R
local maxt = arg.t
local cargs = {damp=arg.d}

function masked_circle(p, r, N, eps, offset)
    return P.objects.MaskedCircle(p, r,
        P.objects.circle_masks.circle_nholes(N, eps, offset),
        cargs
    )
end

local obj, bd = P.ics.hex_grid_object(Ox, Oy, masked_circle, rad, arg.G, arg.g, arg.offset)
local w, h = bd[1], bd[2]
local box = P.objects.Box({0, 0}, {w, h*1.01})
obj[#obj + 1] = box

local fx, fy = arg.p[1], arg.p[2]
local vx, vy = arg.v[1], arg.v[2]

print(vx*w, vy*h)
local conf = {
    dt = 1e-2,
    eps = 1e-4,
    nbl = P.neighborlist.CellNeighborlist(box, {200, 200}, 1e-1),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({fx*w, fy*h}, {vx, vy}, {0, 0})},
    objects = obj,
    observers = {
        P.cli.args_to_observer(arg, box),
        P.observers.TimePrinter(1e5),
        P.interrupts.Collision(box.segments[4])
    },
}

local sim = P.ics.create_simulation(conf)
local t_start = os.clock()
sim:step(maxt)
local t_end = os.clock()
print(t_end - t_start)
