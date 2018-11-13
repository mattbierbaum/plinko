local json = require('dkjson')
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
    local time = 0
    local mint = 2
    local mino = nil
    local seg = objects.Segment(pos0, pos1)

    while true do
        mint = 2
        mino = nil
        for _, obj in pairs(self.objects) do
            local o, t = obj:intersection(seg)
            if t and t < mint and t < 1 and t > 0 then
                mint = t
                mino = o
            end
        end

        if mino then
            time = time + (1 - time)*mint
            local newp = vector.lerp(seg.p0, seg.p1, mint)
            local norm = mino:normal(newp)
            vel = vector.reflect(vel, norm)

            local direction = vector.reflect(vector.vsubv(seg.p1, newp), norm)
            seg.p0 = newp
            seg.p1 = vector.vaddv(newp, direction)
        else
            break
        end

        if time > 1-1e-12 then
            break
        end
    end

    return seg.p1, vel
end

function Simulation:step(steps)
    local p = {}
    local steps = steps or 1
    local seg = objects.Segment({0, 0}, {0, 0})

    for i = 1, steps do
        forces.force_gravity(self.particles)

        for _, part0 in pairs(self.particles) do
            p[#p + 1] = part0.pos
            local part1 = forces.integrate_euler(part0, self.dt)
            part0.pos, part0.vel = self:linear_motion(part0.pos, part1.pos, part1.vel)
        end
    end

    local txt = json.encode(p, {indent=true})
    local file = io.open('./test.json', 'w')
    file:write(txt)
end

local s = Simulation(1e-3)
s:add_object(objects.Box({0, 0}, {1, 1}))
s:add_object(objects.Circle({0.5, 0.5}, 0.25))
s:add_particle(objects.PointParticle({0.6, 0.6}, {0, 0}, {0, 0}))

for i = 1, 1 do
    s:step(10000)
end

util.tprint(s)
