local util = require('util')
local vector = require('vector')
local objects = require('objects')
local forces = require('forces')
local neighborlist = require('neighborlist')
local observers = require('observers')

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
    self.observer_group = observers.ObserverGroup(self.observers)
    self.observer_group:begin()
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

function Simulation:linear_project(part, seg, vel)
    local mint = self._mint
    local mino = self._mino
    local nseg = self._nseg
    local running = true

    for collision = 1, MAX_BOUNCE do
        mint, mino = self:intersection(seg)

        if not mino then
            break
        end

        mint = (1 - self.eps) * mint
        --time = time + (1 - time)*mint

        nseg.p0 = seg.p1
        nseg.p1 = vector.lerp(seg.p0, seg.p1, mint)

        if not self.equal_time then
            vector.copy(nseg.p1, part.pos)
            vector.copy(vel,     part.vel)
            self.observer_group:update_particle(part)
        end
        self.observer_group:update_collision(part0, mino, mint)
        seg, vel = mino:collide(seg, nseg, vel)

        if collision == MAX_BOUNCE-1 then
            print('* Max bounces reached')
            running = false
        end
    end

    return part, seg, vel, running
end

function Simulation:step(steps)
    self._mint = nil
    self._mino = nil
    self._nseg = objects.Segment({0, 0}, {0, 0})

    local steps = steps or 1
    local seg0 = objects.Segment({0, 0}, {0, 0})
    local seg1 = objects.Segment({0, 0}, {0, 0})
    local part0 = objects.PointParticle()
    local part1 = objects.PointParticle()

    local mint, mino = nil, nil
    local time = 0
    local vel = {0, 0}

    for p = 1, #self.particles do
        local particles = self.particles[p]

        for pind = 1, particles:count() do
            --print('particle', pind)
            local is_running = true
            part0 = particles:index(pind)

            for step = 1, steps do
                if not is_running then break end

                self.force_func[1](part0)
                forces.integrate_euler(part0, part1, self.dt)

                vector.copy(part1.vel, vel)
                vector.copy(part0.pos, seg0.p0)
                vector.copy(part1.pos, seg0.p1)
                self.observer_group:update_particle(part0)

                part0, seg0, vel, is_running = self:linear_project(part0, seg0, vel)

                vector.copy(seg0.p1, part0.pos)
                vector.copy(vel,     part0.vel)
                time = time + self.dt
                self.observer_group:update_time(step)

                is_running = is_running and not self.observer_group:is_triggered()
            end

            self.observer_group:reset()
        end
    end

    self.observer_group:close()
end

return {Simulation=Simulation}
