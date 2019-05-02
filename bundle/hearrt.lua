local P = require('plinko')
local argparse = require('lib.argparse')

local opt = argparse(){name='hearrt', description='Draw a heart with bezier curves'}
opt:option('-l', 'Fractional line width', 1e-5, tonumber):argname('linewidth')
opt:option('-t', 'Number of timesteps to simulate', 1.3e5, tonumber):argname('maxt')
opt:option('-k', 'Hookes law spring constant', 2.0, tonumber):argname('k')
opt:option('-p', 'Starting position "%f,%f"', {0.71, 0.31}, P.util.tovec):argname('p0')
opt:option('-v', 'Starting velocity "%f,%f"', {0.011, 0.0151}, P.util.tovec):argname('v0')
opt:argument('filename', 'Filename for SVG output', 'hearrt.svg'):args('?')
local arg = opt:parse(arg)
local fn = arg.filename or 'hearrt.svg'

local HEARRT = {
    {{0.49999, 0.24787}, {0.50197, 0.16331}, {0.53926, 0.09956}, {0.59094, 0.05792}}, 
    {{0.59094, 0.05792}, {0.63832, 0.01973}, {0.69755, 0.00000}, {0.75823, 0.00254}}, 
    {{0.75823, 0.00254}, {0.84038, 0.00759}, {0.89626, 0.04009}, {0.93093, 0.07678}}, 
    {{0.93093, 0.07678}, {0.97530, 0.12810}, {1.00000, 0.18254}, {0.99952, 0.25271}}, 
    {{0.99952, 0.25271}, {0.99571, 0.32804}, {0.98536, 0.35844}, {0.95272, 0.41653}}, 
    {{0.95272, 0.41653}, {0.91112, 0.49057}, {0.89743, 0.49736}, {0.85830, 0.54485}}, 
    {{0.85830, 0.54485}, {0.79178, 0.62332}, {0.71358, 0.68873}, {0.64523, 0.76136}}, 
    {{0.64523, 0.76136}, {0.61745, 0.79209}, {0.57543, 0.83244}, {0.54220, 0.88453}}, 
    {{0.54220, 0.88453}, {0.52114, 0.91755}, {0.50281, 0.95383}, {0.49999, 1.00000}}, 
    {{0.49999, 0.24787}, {0.49802, 0.16331}, {0.46073, 0.09956}, {0.40905, 0.05792}}, 
    {{0.40905, 0.05792}, {0.36167, 0.01973}, {0.30244, 0.00000}, {0.24176, 0.00254}}, 
    {{0.24176, 0.00254}, {0.15961, 0.00759}, {0.10373, 0.04009}, {0.06906, 0.07678}}, 
    {{0.06906, 0.07678}, {0.02469, 0.12810}, {0.00000, 0.18254}, {0.00047, 0.25271}}, 
    {{0.00047, 0.25271}, {0.00428, 0.32804}, {0.01463, 0.35844}, {0.04727, 0.41653}}, 
    {{0.04727, 0.41653}, {0.08887, 0.49057}, {0.10256, 0.49736}, {0.14169, 0.54485}}, 
    {{0.14169, 0.54485}, {0.20821, 0.62332}, {0.28641, 0.68873}, {0.35476, 0.76136}}, 
    {{0.35476, 0.76136}, {0.38254, 0.79209}, {0.42456, 0.83244}, {0.45779, 0.88453}}, 
    {{0.45779, 0.88453}, {0.47885, 0.91755}, {0.49718, 0.95383}, {0.49999, 1.00000}}
}

local beziers = {}

for i = 1, #HEARRT do
    local bez = P.objects.BezierCurve(HEARRT[i])
    beziers[#beziers + 1] = bez
end

local box = P.objects.Box({0, 0}, {1, 1})
local conf = {
    dt = 1e-2,
    eps = 1e-4,
    objects = beziers,
    forces = {P.forces.generate_force_central({0.5, 0.5}, -arg.k)},
    particles = {P.objects.SingleParticle(arg.p, arg.v, {0, 0})},
    observers = {P.observers.SVGLinePlot(fn, box, arg.l)}
}

local s = P.ics.create_simulation(conf)
local t_start = os.clock()
s:step(arg.t)
local t_end = os.clock()
print(t_end - t_start)
