local ics = require('ics')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')

L = 10.0
local f0 = 0.44
local f1 = 0.1
local tmax = 1e6

if #arg == 3 then
    f0 = tonumber(arg[1])
    f1 = tonumber(arg[2])
    tmax = tonumber(arg[3])
else
    print('orbits <vx> <vy> <t_max>')
    print('suggestions:')
    print('\t0.1 0.44 1e6')
    os.exit()
end

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    forces = {forces.force_gravity},
    particles = {objects.SingleParticle({L, 1.9*L}, {-f0*L, -f1*L}, {0, 0})},
    objects = {objects.Circle({L, L}, L, {damp=1.0})},
    observers = {observers.SVGLinePlot('./orbits.svg', objects.Box({0, 0}, {2*L, 2*L}), L*4e-6)}
}

local s = ics.create_simulation(conf)
s:step(tmax)
