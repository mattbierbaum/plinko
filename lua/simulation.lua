local json = require('dkjson')
local util = require('util')
local vector = require('vector')
local objects = require('objects')
local forces = require('forces')
local neighborlist = require('neighborlist')

local MAX_BOUNCE = 10000

Simulation = util.class()
function Simulation:init(dt, eps)
    self.t = 0
    self.dt = dt
    self.eps = eps or 1e-10
    self.equal_time = false
    self.objects = {}
    self.particles = {}
    self.force_func = {}
    self.observers = {}

    self.nbl = neighborlist.NaiveNeighborlist()
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

function Simulation:add_observer(obv)
    self.observers[#self.observers + 1] = obv
end

function Simulation:initalize()
    for i = 1, #self.observers do
        self.observers[i]:begin()
    end
end

function Simulation:set_neighborlist(nbl)
    self.nbl = nbl
    for i = 1, #self.objects do
        self.nbl:append(self.objects[i])
    end
    self.nbl:calculate()
end

function Simulation:intersection_bruteforce(seg)
    local mint = 2
    local mino = nil

    for ind = 1, #self.objects do
        local obj = self.objects[ind]
        local o, t = obj:intersection(seg)
        if t and t < mint and t <= 1 and t > 0 then
            mint = t
            mino = o
        end
    end

    return mint, mino
end

function Simulation:intersection(seg)
    local mint = 2
    local mino = nil

    local objs = self.nbl:near(seg)
    for ind = 1, #objs do
        local obj = objs[ind]
        local o, t = obj:intersection(seg)
        if t and t < mint and t <= 1 and t >= 0 then
            mint = t
            mino = o
        end
    end

    return mint, mino
end

function Simulation:step(steps)
    local steps = steps or 1
    local seg0 = objects.Segment({0, 0}, {0, 0})
    local seg1 = objects.Segment({0, 0}, {0, 0})
    local part0 = objects.PointParticle()
    local part1 = objects.PointParticle()

    local time = 0
    local mint = 2
    local mino = nil
    local vel = {0, 0}

    for step = 1, steps do
        self.force_func[1](self.particles)

        for particle = 1, #self.particles do 
            part0 = self.particles[particle]
            forces.integrate_euler(part0, part1, self.dt)

            vel = part1.vel
            vector.copy(part0.pos, seg0.p0)
            vector.copy(part1.pos, seg0.p1)

            for obv = 1, #self.observers do
                self.observers[obv]:update(part0.pos)
            end

            for collision = 1, MAX_BOUNCE do
                local mint, mino = self:intersection(seg0)

                if not mino then
                    break
                end

                mint = (1 - self.eps) * mint
                time = time + (1 - time)*mint

                seg1.p0 = seg0.p1
                seg1.p1 = vector.lerp(seg0.p0, seg0.p1, mint)

                if not self.equal_time then
                    for obv = 1, #self.observers do
                        self.observers[obv]:update(seg1.p1)
                    end
                end

                local norm = mino:normal(seg1)
                local dir = vector.reflect(vector.vsubv(seg0.p1, seg1.p1), norm)

                seg0.p0 = seg1.p1
                seg0.p1 = vector.vaddv(seg1.p1, dir)
                vel = vector.reflect(vel, norm)

                if collision == MAX_BOUNCE-1 then
                    print('*')
                    os.exit()
                end
            end

            vector.copy(seg0.p1, part0.pos)
            vector.copy(vel, part0.vel)
        end
    end

    for obv = 1, #self.observers do
        self.observers[obv]:close()
    end
end

return {Simulation=Simulation}
