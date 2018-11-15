local vector = require('vector')
local util = require('util')

local forces = {}

function forces.force_central(particles)
    for i = 1, #particles do
        local p = particles[i]
        p.acc[1] = 0.5 - p.pos[1]
        p.acc[2] = 0.5 - p.pos[2]
    end
end

function forces.force_gravity(particles)
    for i = 1, #particles do
        local p = particles[i]
        p.acc[1] = 0
        p.acc[2] = -1
    end
end

function forces.force_none(particles)
    for i = 1, #particles do
        local p = particles[i]
        p.acc[1] = 0
        p.acc[2] = 0
    end
end

function forces.integrate_euler(p0, p1, dt)
    p1.vel[1] = p0.vel[1] + p0.acc[1] * dt
    p1.vel[2] = p0.vel[2] + p0.acc[2] * dt

    p1.pos[1] = p0.pos[1] + p1.vel[1] * dt
    p1.pos[2] = p0.pos[2] + p1.vel[2] * dt
end

return forces
