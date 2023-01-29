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
local wseg = objects.Segment({0, 0}, {0, 0})
local vseg = objects.Segment({0, 0}, {0, 0})
local part0 = objects.PointParticle(nil, nil, nil, -100)
local part1 = objects.PointParticle(nil, nil, nil, -100)
local vel = {0, 0}

local Simulation = util.class()
function Simulation:init(dt, eps)
    self.t = 0
    self.dt = dt
    self.eps = eps or 1e-6
    self.equal_time = false
    self.objects = {}
    self.particle_groups = {}
    self.force_func = {}
    self.observers = {}
    self.integrator = nil

    self.nbl = neighborlist.NaiveNeighborlist()
end

function Simulation:add_object(obj)
    index = #self.objects + 1
    obj:set_object_index(index)
    self.objects[index] = obj
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

function Simulation:initialize()
    self.observer_group = observers.ObserverGroup(self.observers)
    self.observer_group:begin()
end

function Simulation:set_integrator(integrator)
    self.integrator = integrator
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

function Simulation:linear_project(part, pseg, vseg)
    local running = true

    for collision = 1, MAX_BOUNCE do
        local mint, mino = self:intersection(pseg)

        if not mino then
            break
        end

        mint = (1 - self.eps) * mint

        nseg.p0 = pseg.p1
        nseg.p1 = vector.lerp(pseg.p0, pseg.p1, mint)

        wseg.p0 = vseg.p1
        wseg.p1 = vector.lerp(vseg.p0, vseg.p1, mint)

        self.observer_group:update_collision(part0, mino, mint)
        pseg, vseg = mino:collide(pseg, nseg, wseg)

        if not self.equal_time then
            vector.copy(pseg.p0, part.pos)
            vector.copy(vseg.p0, part.vel)
            self.observer_group:update_particle(part)
        end

        if collision == MAX_BOUNCE then
            print('* Max bounces reached')
            running = false
        end
    end

    return part, pseg, vseg, running
end

function Simulation:step_particle(in_part)
    part0:copy(in_part)
    self.observer_group:set_particle(part0)

    if not part0.active then
        return
    end

    self.integrator(part0, part1, self.dt)

    vector.copy(part0.vel, vseg.p0)
    vector.copy(part0.pos, pseg.p0)
    vector.copy(part1.vel, vseg.p1)
    vector.copy(part1.pos, pseg.p1)
    part0, pseg, vseg, is_running = self:linear_project(part0, pseg, vseg)

    vector.copy(pseg.p1, part0.pos)
    vector.copy(vseg.p1, part0.vel)
    self.observer_group:update_particle(part0)

    part0.active = part0.active and not self.observer_group:is_triggered_particle(part0)
    in_part:copy(part0)
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

        if self.observer_group:is_triggered() then
            break
        end
    end

    self.observer_group:close()
end

function Simulation:run()
    self:step(1e100)
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
