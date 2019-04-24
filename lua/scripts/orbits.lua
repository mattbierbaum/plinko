local ics = require('ics')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')
local plotting_image = require('plotting_image')

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
    print('\t0.60 0.35 3e6')
    print('\t0.50 0.50 3e6')
    print('\t0.50 0.60 1e6')
    print('\t0.50 0.63 6e6')
    print('\t0.20 0.75 1e6')
    os.exit()
end

local box = objects.Box({0, 0}, {2*L, 2*L})
local conf = {
    dt = 1e-2,
    eps = 1e-4,
    forces = {forces.force_gravity},
    particles = {objects.SingleParticle({0.53*L, 0.2*L}, {-f0*L, -f1*L}, {0, 0})},
    objects = {objects.Circle({L, L}, L, {damp=1.0})},
    observers = {
        observers.ImageRecorder('./orbits.pgm',
            plotting_image.DensityPlot(box, 3200/(2*L)), 'pgm5'
        ),
        observers.SVGLinePlot('./orbits.svg', box, L*4e-6)
    }
}

local s = ics.create_simulation(conf)
s:step(tmax)
