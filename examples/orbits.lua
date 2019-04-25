local ics = require('ics')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')
local plotting_image = require('plotting_image')

L = 10.0
local f0 = 0.44
local f1 = 0.1
local bump = 0.0
local tmax = 1e6

if #arg == 4 then
    f0 = tonumber(arg[1])
    f1 = tonumber(arg[2])
    bump = tonumber(arg[3])
    tmax = tonumber(arg[4])
else
    print('orbits <vx> <vy> <bump_size> <t_max>')
    print('suggestions:')
    print('\t0.60 0.35 0 3e6')
    print('\t0.60 0.35 0 3e7')
    print('\t0.50 0.50 0 3e6')
    print('\t0.50 0.60 0 1e6')
    print('\t0.50 0.63 0 6e6')
    print('\t0.20 0.75 0 1e6')
    os.exit()
end

local box = objects.Box({0, 0}, {2*L, 2*L})
local conf = {
    dt = 1e-2,
    eps = 1e-4,
    forces = {forces.force_gravity},
    particles = {objects.SingleParticle({0.53*L, 0.2*L}, {-f0*L, -f1*L}, {0, 0})},
    objects = {
        objects.Circle({L, 0}, bump*L),
        objects.Circle({L, L}, L)
    },
    observers = {
        observers.ImageRecorder('./orbits.pgm',
            plotting_image.DensityPlot(box, 3200/(2*L)), 'pgm5'
        ),
    }
}

local s = ics.create_simulation(conf)
s:step(tmax)
