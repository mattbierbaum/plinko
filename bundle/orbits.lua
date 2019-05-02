local P = require('plinko')
local argparse = require('lib.argparse')

local epilog = [[Suggestions:
     vx      vy      bump   time
     0.60    0.35    0      3e6
     0.60    0.35    0      3e7
     0.50    0.50    0      3e6
     0.50    0.60    0      1e6
     0.50    0.63    0      6e6
     0.20    0.75    0      1e6]]

local opt = argparse(){
    name='orbits',
    description='Orbit paths within a circle',
    epilog=epilog
}
opt:option('-b', 'Fractional bump size', 0.0, tonumber):argname('bump')
opt:option('-t', 'Number of timesteps to simulate', 3e6, tonumber):argname('maxt')
opt:option('-L', 'Number of pixels for each dimension', 3200, tonumber):argname('pix')
opt:option('-p', 'Starting position "%f,%f"', {0.53, 0.20}, P.util.tovec):argname('p0')
opt:option('-v', 'Starting velocity "%f,%f"', {0.6, 0.35}, P.util.tovec):argname('v0')
opt:argument('filename', 'Filename for PGM output', 'orbits.pgm'):args('?')
local arg = opt:parse(arg)
local fn = arg.filename or 'orbits.pgm'

local L = 10.0
local f0 = arg.v[1]
local f1 = arg.v[2]
local p0 = arg.p[1]
local p1 = arg.p[2]
local bump = arg.b
local tmax = arg.t

local box = P.objects.Box({0, 0}, {2*L, 2*L})
local conf = {
    dt = 1e-2,
    eps = 1e-4,
    forces = {P.forces.force_gravity},
    particles = {P.objects.SingleParticle({p0*L, p1*L}, {-f0*L, -f1*L}, {0, 0})},
    objects = {
        P.objects.Circle({L, 0}, bump*L),
        P.objects.Circle({L, L}, L)
    },
    observers = {
        P.observers.ImageRecorder(fn, P.plotting.DensityPlot(box, arg.L/(2*L)), 'pgm5')
    }
}

local s = P.ics.create_simulation(conf)
s:step(tmax)
