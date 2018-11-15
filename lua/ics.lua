local simulation = require('simulation')
local objects = require('objects')
local forces = require('forces')
local vector = require('vector')

local ics = {}

function ics.single_circle()
    return {
        forces = {forces.force_gravity},
        particles = {objects.PointParticle({0.65, 0.5}, {0, 0}, {0, 0})},
        objects = {objects.Circle({0.5, 0.5}, 0.25)}
    }
end

function ics.halfmoon()
    return {
        forces = {forces.force_central},
        particles = {objects.PointParticle({0.71, 0.6}, {0.1, 0}, {0, 0})},
        objects = {
            objects.Circle({0.3, 0.5}, 0.25),
            objects.Circle({0.6, 0.5}, 0.025),
            objects.Circle({0.58, 0.42}, 0.010),
            objects.Circle({0.58, 0.58}, 0.010)
        }
    }
end

function ics.circle_circles(N, radmin, radmax, R)
    local N = N or 10
    local R = R or 0.5
    local radmin = radmin or 0.001
    local radmax = radmax or 0.05
    local center = {0.5, 0.5}

    local obj = {
        objects.Circle(vector.vaddv(center, {R, 0}), radmax),
        objects.Circle(vector.vaddv(center, {-R, 0}), radmin),
        --objects.Circle(center, 0.1)
    }
    for i = 1, N-1 do
        local theta = i * math.pi / N
        local pos0 = {R*math.cos(theta), R*math.sin(theta)}
        local pos1 = {R*math.cos(theta), -R*math.sin(theta)}
        local rad = i * (radmax - radmin) / N + radmin
        obj[#obj + 1] = objects.Circle(vector.vaddv(center, pos0), rad)
        obj[#obj + 1] = objects.Circle(vector.vaddv(center, pos1), rad)
    end

    return {
        forces = {forces.force_central},
        particles = {objects.PointParticle({0.5, 0.53}, {0.7, 0}, {0, 0})},
        objects = obj
    }
end

function ics.free_particle()
    return {
        forces = {forces.force_central},
        particles = {objects.PointParticle({0.5, 0.6}, {0, 0}, {0, 0})},
        objects = {}
    }
end

function ics.create_simulation(conf)
    local s = simulation.Simulation(1e-2)
    for _, i in pairs(conf.forces) do
        s:add_force(i)
    end

    for _, i in pairs(conf.objects) do
        s:add_object(i)
    end

    for _, i in pairs(conf.particles) do
        s:add_particle(i)
    end
    return s
end

return ics
