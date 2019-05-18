local P = require('plinko')

local argparse = require('lib.argparse')
local opt = argparse(){name='concentric'}
opt:option('-g', 'Circle slit size, 4 per circle', '1e-3', tonumber):argname('gap')
opt:option('-r', 'Ratio of outer to inner circle radius', '0.76', tonumber):argname('ratio')
opt:option('-d', 'Collision damping constant', '1.0', tonumber):argname('damp')
opt:option('-t', 'Max time', '1e7', tonumber):argname('maxt')
opt:option('-N', 'Number of circles', '8', tonumber):argname('N')
opt:option('-p', 'Starting position "%f,%f"', '0.501,0.85', P.util.tovec):argname('p0')
opt:option('-v', 'Starting velocity "%f,%f"', '0.3,0.0', P.util.tovec):argname('v0')
P.cli.options_seed(opt, '10')
P.cli.options_observer(opt, 'concentric.pgm', '1e3')
local arg = opt:parse(arg)

local cargs = {damp=arg.d}
local N = arg.N
local eps = arg.g
local rat = arg.r
local maxt = arg.t
local p0 = arg.p
local v0 = arg.v

local box = P.objects.Box({0, 0}, {1, 1})
function concentric_circles(N, minr, eps)
    local p = {0.5, 0.5}
    local dr = (0.5 - minr) / N
    local objs = {box, P.objects.Circle(p, 0.49)}

    for i = 1, N do
        local r = 0.5 - dr * i
        objs[#objs + 1] = P.objects.MaskedCircle(p, r,
            P.objects.circle_masks.circle_nholes(4, eps, math.pi/4 * (i % 2))
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
