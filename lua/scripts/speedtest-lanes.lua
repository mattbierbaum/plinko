local lanes = require('lanes').configure{
    on_state_create = function()
        local objects = require('objects')
        local struct = require('struct')
    end
}
local linda = lanes.linda()

local ics = require('ics')
local neighborlist = require('neighborlist')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')

local conf = {
    dt = 1e-2,
    eps = 1e-5,
    forces = {forces.force_gravity},
    particles = {
        objects.SingleParticle({0.501, 0.85}, {0.3, 0.1}, {0, 0}),
        objects.SingleParticle({0.511, 0.85}, {0.3, 0.1}, {0, 0})
    },
    objects = {
        objects.Box({0, 0}, {1, 1}),
        objects.Box({.1, .1}, {.2, .2}),
        objects.Circle({0.5, 0.5}, 0.25)
    },
    observers = {
        observers.TimePrinter(1e6)
    },
}

local s0 = ics.create_simulation(conf)
local s1 = ics.create_simulation(conf)

function step(s, i, p)
    --print('================')
    --print(i)
    --print(s)
    --print(s.objects)
    --print(s.step)
    --print(s.eps)
    --print(s.objects[1].uu[1])
    --print(s.particle_groups[1]:index(1).pos[1])
    s:step(i, p)
    print(s.particle_groups[p]:index(1).pos[1])
    print(s.info[1], s.info[2])
end
N = 1e6

local t_start = os.clock()
local l0 = lanes.gen('*', step)(s0, N, 1)
local l1 = lanes.gen('*', step)(s0, N, 2)
l0:join()
l1:join()
local t_end = os.clock()
print(t_end - t_start)

print(s0.particle_groups[1]:index(1).pos[1])
print(s0.particle_groups[2]:index(1).pos[1])
print(s0.info[1], s0.info[2])
--local t_start = os.clock()
--s0:step(1e7)
--local t_end = os.clock()
--print(t_end - t_start)

