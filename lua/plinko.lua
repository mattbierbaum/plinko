local util = require('util')
local vector = require('vector')
local objects = require('objects')
local forces = require('forces')

Simulation = util.class()
function Simulation:init(dt)
    self.t = 0
    self.dt = dt
    self.objects = {}
    self.particles = {}

    self._t = objects.Segment()
end

function Simulation:add_object(obj)
    self.objects[#self.objects + 1] = obj
end

function Simulation:add_particle(particle)
    self.particles[#self.particles + 1] = particle
end

function Simulation:linear_motion(pos0, pos1, vel)
    local mint = 2
    local mino = nil
    local seg = objects.Segment(pos0, pos1)

    for _, obj in pairs(self.objects) do
        local o, t = obj:intersection(seg)
        if t and t < mint and t < 1 and t > 0 then
            mint = t
            mino = o
        end
    end

    if mino then
        local newp = vector.lerp(seg.p0, seg.p1, mint)
        local norm = mino:normal(newp)
        local newv = vector.reflect(part1.vel, norm)

        return self:linear_motion(newp, pos1, newv)
    end

end

function Simulation:step(steps)
    local steps = steps or 1
    local part1 = nil
    local seg = objects.Segment({0, 0}, {0, 0})

    for i = 1, steps do
        for _, part0 in pairs(self.particles) do
            part0.acc = forces.force_gravity()
            part1 = forces.integrate_euler(part0, self.dt)

            part0.pos = part1.pos
            part0.vel = part1.vel
        end
    end
end

local s = Simulation(1e-2)
s:add_object(objects.Box({0, 0}, {1, 1}))
s:add_object(objects.Circle({0.5, 0.5}, 0.25))
s:add_particle(objects.PointParticle({0.5, 0.9}, {0, 0}, {0, 0}))

for i = 1, 100 do
    s:step()
end

util.tprint(s)
