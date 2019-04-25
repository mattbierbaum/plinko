local util = require('plinko.util')
local vector = require('plinko.vector')
local objects = require('plinko.objects')
local forces = require('plinko.forces')
local neighborlist = require('plinko.neighborlist')
local observers = require('plinko.observers')

local MAX_BOUNCE = 10000

-- a bunch of module-local items to save on gc
local nseg = objects.Segment({0, 0}, {0, 0})
local pseg = objects.Segment({0, 0}, {0, 0})
local part0 = objects.PointParticle()
local part1 = objects.PointParticle()
local vel = {0, 0}

Simulation = util.class()
function Simulation:init(dt, eps)
    self.t = 0
    self.dt = dt
    self.eps = eps or 1e-6
    self.equal_time = false
    self.objects = {}
    self.particle_groups = {}
    self.force_func = {}
    self.observers = {}

    self.nbl = neighborlist.NaiveNeighborlist()
end

function Simulation:add_object(obj)
    self.objects[#self.objects + 1] = obj
end

function Simulation:add_particle(particle)
    self.particle_groups[#self.particle_groups + 1] = particle
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
    local running = true

    for collision = 1, MAX_BOUNCE do
        local mint, mino = self:intersection(seg)

        if not mino then
            break
        end

        mint = (1 - self.eps) * mint

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

function Simulation:step_particle(part0)
    self.observer_group:set_particle(part0)

    if not part0.active then
        return
    end

    forces.integrate_euler(part0, part1, self.dt)

    vector.copy(part1.vel, vel)
    vector.copy(part0.pos, pseg.p0)
    vector.copy(part1.pos, pseg.p1)
    self.observer_group:update_particle(part0)

    part0, pseg, vel, is_running = self:linear_project(part0, pseg, vel)

    vector.copy(pseg.p1, part0.pos)
    vector.copy(vel,     part0.vel)
    self.observer_group:update_particle(part0)

    part0.active = part0.active and not self.observer_group:is_triggered()
    self.observer_group:reset()
end

function Simulation:step(steps)
    local steps = steps or 1
    for step = 1, steps do
        for p = 1, #self.particle_groups do
            local particles = self.particle_groups[p]
            self.force_func[1](particles)

            for pind = 1, particles:count() do
                self:step_particle(particles:index(pind))
            end
        end

        self.t = self.t + self.dt
        self.observer_group:update_time(step)
    end

    self.observer_group:close()
end

function Simulation:parallelize(threads)
    local lanes = require('lanes').configure()
    local linda = lanes.linda()
    local parts = self.particle_groups[1]:partition(threads)

    function stepper(sim, particles, index)
        sim.particle_groups = {particles}
        while true do
            local k, v = linda:receive(1e3, tostring(index))

            if not v then
                print('Thread timeout, stopping...')
                break
            end

            if v == -1 then
                print('Recieved cleanup signal, stopping...')
                break
            end
            sim:step(v)
        end
    end

    local out = {}
    for i = 1, threads do
        local th = lanes.gen('*', stepper)(self, parts[i], i)
        out[i] = th
    end

    function step(n)
        for i = 1, threads do
            linda:send(tostring(i), n)
        end
    end

    return step, out
end
return {Simulation=Simulation}