local P = require('plinko')

local box = P.objects.Box({0, 0}, {1, 1})
local conf = {
    objects = {box},
    forces = {P.forces.generate_force_central({0.5, 0.5}, 9.0)},
    particles = {P.objects.SingleParticle({0.63, 0.63}, {1.5, 1.3}, {0, 0})},
    observers = {P.observers.SVGLinePlot('freeparticle.svg', box, 1e-5)}
}

P.ics.create_simulation(conf):step(1e4)
