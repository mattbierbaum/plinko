local vector = require('plinko.vector')
local util = require('plinko.util')

local forces = {}

function forces.apply_independent_forces(particles, func)
    for i = 1, particles:count() do
        func(particles:index(i))
    end
end

local function _force_central(c, k)
    return function(p)
        p.acc[1] = k*(c[1] - p.pos[1])
        p.acc[2] = k*(c[2] - p.pos[2])
    end
end

local function _force_central_invert(p)
    p.acc[1] = p.pos[1] - 0.5
    p.acc[2] = p.pos[2] - 0.5
end

local function _force_gravity(p)
    p.acc[1] = 0
    p.acc[2] = -1
end

function forces.force_gravity(particles)
    return forces.apply_independent_forces(particles, _force_gravity)
end

function forces.generate_force_central(c, k)
    util.tprint(c)
    local func = _force_central(c, k)
    return function(p)
        return forces.apply_independent_forces(p, func)
    end
end

local function _force_gravity_invert(p)
    p.acc[1] = 0
    p.acc[2] = 1
end

local function _force_none(p)
    p.acc[1] = 0
    p.acc[2] = 0
end

function forces.integrate_euler(p0, p1, dt)
    p1.vel[1] = p0.vel[1] + p0.acc[1] * dt
    p1.vel[2] = p0.vel[2] + p0.acc[2] * dt

    p1.pos[1] = p0.pos[1] + p1.vel[1] * dt
    p1.pos[2] = p0.pos[2] + p1.vel[2] * dt
end

return forces