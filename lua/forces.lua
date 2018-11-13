local vector = require('vector')
local util = require('util')

local forces = {}

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
    local outv = vector.vaddv(vel, vector.vmuls(acc, dt))
    local outp = vector.vaddv(pos, vector.vmuls(outv, dt))

    return {pos=outp; vel=outv; acc=acc}
end

return forces
