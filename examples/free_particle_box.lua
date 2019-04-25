local ics = require('plinko.ics')
local forces = require('plinko.forces')
local objects = require('plinko.objects')

local conf = {
    forces = {forces.generate_force_central({0,0}, -1.0)},
    particles = {objects.SingleParticle({0.5, 0.6}, {0, 0}, {0, 0})},
    objects = {}
}

local sim = ics.create_simulation(conf)
sim:step(1e3)
