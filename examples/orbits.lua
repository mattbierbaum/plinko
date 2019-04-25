local P = require('plinko')

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

local box = P.objects.Box({0, 0}, {2*L, 2*L})
local conf = {
    dt = 1e-2,
    eps = 1e-4,
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({0.53*L, 0.2*L}, {-f0*L, -f1*L}, {0, 0})},
    objects = {
        P.objects.Circle({L, 0}, bump*L),
        P.objects.Circle({L, L}, L)
    },
    observers = {
        P.observers.ImageRecorder('./orbits.pgm',
            P.plotting.DensityPlot(box, 3200/(2*L)), 'pgm5'
        ),
    }
}

local s = P.ics.create_simulation(conf)
s:step(tmax)
