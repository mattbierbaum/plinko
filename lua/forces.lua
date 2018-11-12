local vector = require('vector')
local util = require('util')

local forces = {}

function forces.force_gravity(...)
    return {0, -1}
end

function forces.force_none(...)
    return {0, 0}
end

function forces.integrate_euler(particle, dt)
    local pos, vel, acc = particle.pos, particle.vel, particle.acc
    local outv = vector.vaddv(vel, vector.vmuls(acc, dt))
    local outp = vector.vaddv(pos, vector.vmuls(outv, dt))

    return {pos=outp; vel=outv; acc=acc}
end

return forces
