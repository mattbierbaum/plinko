local P = require('plinko')
local argparse = require('lib.argparse')

local opt = argparse(){name='hexngons'}
opt:option('-R', 'Radius of polygon cirumscribed circle', '0.577255', tonumber):argname('gap')
opt:option('-d', 'Collsion damping constant.', '1.0', tonumber):argname('damp')
opt:option('-N', 'Number of rows, cols', '8,16', P.util.tovec):argname('N')
opt:option('-v', 'Starting velocity "%f,%f"', '0.1,0.0', P.util.tovec):argname('v0')
opt:option('-p', 'Starting position "%f,%f"', '0.0,0.0', P.util.tovec):argname('v0')
opt:option('-S', 'Polygon sides', '4', tonumber):argname('sides')
P.cli.options_seed(opt, '100')
P.cli.options_observer(opt, 'hexngons.pgm', '4e3')
local arg = opt:parse(arg)

local O = arg.N
local rad = arg.R
local damp = arg.d
local p0 = arg.p
local v0 = arg.v

math.randomseed(arg.seed)
function rotated_octagon(pos, rad)
    return P.ics.obj_funcs.ngon(pos, rad, arg.S, {damp=damp}):rotate(math.random()*math.pi*2)
end

local obj, bd = P.ics.hex_grid_object(O[1], O[2], rotated_octagon, rad)
local max = math.max(bd[1], bd[2]*1.3)
local box0 = P.objects.Box({0, 0}, bd)
local box1 = P.objects.Box({0, 0}, {bd[1], bd[2]*1.3})
local box2 = P.objects.Box({0, 0}, {max, max})
obj[#obj + 1] = box0

local h = bd[2]
local w = bd[1]

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    nbl = P.neighborlist.CellNeighborlist(box1, {200, 200}, 1e-1),
    forces = {P.forces.force_gravity},
    particles = {
        P.objects.SingleParticle({w/2+p0[1], h-0.5+p0[2]}, v0, {0, 0}),
    },
    objects = obj,
    observers = {
        P.cli.args_to_observer(arg, box0),
        P.observers.TimePrinter(1e6),
        P.interrupts.Collision(box0.segments[4])
    },
}

local s = P.ics.create_simulation(conf)
s:step(5e6)
