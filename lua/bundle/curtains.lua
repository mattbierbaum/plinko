local P = require('plinko')
local argparse = require('lib.argparse')

local opt = argparse(){name='curtains'}
opt:option('-g', 'Fractional gap between circles.', '1e-3', tonumber):argname('gap')
opt:option('-d', 'Collision damping constant', '1.0', tonumber):argname('damp')
opt:option('-N', 'Number of rows, cols', '8,8', P.util.tovec):argname('N')
opt:option('-v', 'Starting velocity "%f,%f"', '0.3,0.0', P.util.tovec):argname('v0')
P.cli.options_seed(opt, '10')
P.cli.options_observer(opt, 'curtains.pgm', '4e3')
local arg = opt:parse(arg)

local O = arg.N
local vel = arg.v
local rad = 0.5*(1 - arg.g)
local cargs = {damp=arg.d}

function hemisphere(p)
    return P.objects.MaskedCircle(p, rad,
        P.objects.circle_masks.circle_angle_range(math.pi, 2*math.pi), cargs
    )
end

local obj, bd = P.ics.hex_grid_object(O[1], O[2], hemisphere)
local w, h = bd[1], bd[2]
local box = P.objects.Box({0, 0}, {w, h*1.0})
obj[#obj + 1] = box

vel[1] = vel[1] * (2*math.random()-1)
vel[2] = vel[2] * (2*math.random()-1)

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    nbl = P.neighborlist.CellNeighborlist(box, {200, 200}, 1e-1),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({w/2, h}, vel, {0, 0})},
    objects = obj,
    observers = {
        P.cli.args_to_observer(arg, box),
        P.observers.TimePrinter(1e6),
        P.interrupts.Collision(box.segments[4])
    },
}

P.ics.create_simulation(conf):run()
