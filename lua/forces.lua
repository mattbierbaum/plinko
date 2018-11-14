local vector = require('vector')
local util = require('util')

local forces = {}

function forces.force_central(particles)
    for _, p in pairs(particles) do
        p.acc = vector.vsubv({0.5, 0.5}, p.pos)
    end
end

function forces.force_gravity(particles)
    for _, p in pairs(particles) do
        p.acc = {0, -1}
    end
end

function forces.force_none(particles)
    for _, p in pairs(particles) do
        p.acc = {0, 0}
    end
end

function forces.integrate_euler(particle, dt)
    local pos, vel, acc = particle.pos, particle.vel, particle.acc
    local outv = {
        vel[1] + acc[1] * dt,
        vel[2] + acc[2] * dt
    }
    local outp = {
        pos[1] + outv[1] * dt,
        pos[2] + outv[2] * dt
    }

    return {pos=outp; vel=outv; acc=acc}
end

return forces
