local forces = require('forces')
local objects = require('objects')

local conf = {
    forces = {forces.force_central},
    particles = {objects.SingleParticle({0.5, 0.6}, {0, 0}, {0, 0})},
    objects = {}
}

