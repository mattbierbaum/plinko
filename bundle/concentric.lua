local P = require('plinko')

local argparse = require('lib.argparse')
local opt = argparse(){
    name='concentric',
    epilog=[[
Suggestions:

concentric -g 5e-3 -t 4e6 -r 10000 -N 250 -R 0.1 -p 0.501,0.87
concentric -g 51e-3 -t 6e6 -r 8000 -N 100 -R 0.1 --offset 0.4 -H 2
concentric -g 0.1 -t 2e6 -r 8000 -N 200 -R 0.3 --offset 0.5 -H 2
concentric -g 0.25 -t 2e6 -r 8000 -N 200 -R 0.05 --offset 0.275 -H 1 -p 0.5,0.52
concentric -R 0.01 -g 2e-2 -N 1000 -t 1e5 -p 0.501,0.55 -v 3.1,0 -r 10000 
           --offset 0.0 -H 12
]]
}
opt:option('-g', 'Circle slit size, 4 per circle', '1e-3', tonumber):argname('gap')
opt:option('-R', 'Ratio of outer to inner circle radius', '0.76', tonumber):argname('ratio')
opt:option('-d', 'Collision damping constant', '1.0', tonumber):argname('damp')
opt:option('-t', 'Max time', '1e7', tonumber):argname('maxt')
opt:option('-N', 'Number of circles', '8', tonumber):argname('N')
opt:option('-H', 'Number of holes', '4', tonumber):argname('H')
opt:option('--rand', 'Randomize hole placement', '0', tonumber)
opt:option('--offset', 'Hole placement offset in fractions of a circle', '0.25', tonumber)
opt:option('-p', 'Starting position "%f,%f"', '0.501,0.85', P.util.tovec):argname('p0')
opt:option('-v', 'Starting velocity "%f,%f"', '0.3,0.0', P.util.tovec):argname('v0')
P.cli.options_seed(opt, '10')
P.cli.options_observer(opt, 'concentric.pgm', '1e3')
local arg = opt:parse(arg)

local cargs = {damp=arg.d}
local N = arg.N
local eps = arg.g
local rat = arg.R
local maxt = arg.t
local p0 = arg.p
local v0 = arg.v
local H = arg.H
local dorand = arg.rand
local off = arg.offset

local box = P.objects.Box({0, 0}, {1, 1})
function concentric_circles(N, minr, eps)
    local p = {0.5, 0.5}
    local dr = (0.5 - minr) / N
    local objs = {box, P.objects.Circle(p, 0.49)}

    for i = 1, N do
        local r = 0.5 - dr * i
        objs[#objs + 1] = P.objects.MaskedCircle(p, r,
            P.objects.circle_masks.circle_nholes(H, eps, 2*math.pi*math.random()*dorand + math.pi*off)
        )
    end

    return objs
end

local conf = {
    dt = 1e-3,
    eps = 1e-6,
    nbl = P.neighborlist.CellNeighborlist(
        P.objects.Box({0, 0}, {1, 1}), {100, 100}
    ),
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle(p0, v0, {0, 0})},
    objects = concentric_circles(N, 0.5*rat, eps),
    observers = {
        P.cli.args_to_observer(arg, box),
        P.observers.TimePrinter(1e6)
    },
}

local s = P.ics.create_simulation(conf)
local t_start = os.clock()
s:step(maxt)
local t_end = os.clock()
print(t_end - t_start)
