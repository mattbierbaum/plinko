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
    self.force_func = {}

    self._t = objects.Segment()
end

function Simulation:add_object(obj)
    self.objects[#self.objects + 1] = obj
end

function Simulation:add_particle(particle)
    self.particles[#self.particles + 1] = particle
end

function Simulation:add_force(func)
    self.force_func[#self.force_func + 1] = func
end

function Simulation:step(steps)
    local p = {}
    local steps = steps or 1
    local seg = objects.Segment({0, 0}, {0, 0})
    local part1 = nil

    for i = 1, steps do
        self.force_func[1](self.particles)

        for _, part0 in pairs(self.particles) do
            p[#p + 1] = part0.pos
            part1 = forces.integrate_euler(part0, self.dt)

            vel = part1.vel
            seg.p0 = part0.pos
            seg.p1 = part1.pos

            local num = 1
            while true do
                local mint = 2
                local mino = nil
                for _, obj in pairs(self.objects) do
                    local o, t = obj:intersection(seg)
                    if t and t < mint and t < 1 and t > 0 then
                        mint = t
                        mino = o
                    end
                end

                if mino then
                    mint = mint - 1e-10*mint
                    --time = time + (1 - time)*mint
                    local newp = vector.lerp(seg.p0, seg.p1, mint)
                    local norm = mino:normal(Segment(seg.p0, newp))
                    local direction = vector.reflect(vector.vsubv(seg.p1, newp), norm)
                    vel = vector.reflect(vel, norm)
                    seg.p0 = newp
                    seg.p1 = vector.vaddv(newp, direction)

                    p[#p + 1] = newp
                else
                    break
                end

                num = num + 1
            end

            part0.pos, part0.vel = seg.p1, vel
        end
    end

    local txt = json.encode(p, {indent=true})
    local file = io.open('./test.json', 'w')
    file:write(txt)
end

local s = Simulation(1e-2)
s:add_force(forces.force_central)
s:add_object(objects.Box({0, 0}, {1, 1}))
s:add_object(objects.Circle({0.5, 0.5}, 0.25))
s:add_object(objects.Circle({0.3, 0.5}, 0.25))
s:add_object(objects.Circle({0.6, 0.5}, 0.025))
s:add_object(objects.Circle({0.58, 0.42}, 0.010))
s:add_object(objects.Circle({0.58, 0.58}, 0.010))
s:add_particle(objects.PointParticle({0.71, 0.6}, {0.1, 0}, {0, 0}))

for i = 1, 1 do
    s:step(300000)
end
