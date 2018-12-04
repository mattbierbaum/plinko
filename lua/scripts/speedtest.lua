local ics = require('ics')
local neighborlist = require('neighborlist')
local forces = require('forces')
local objects = require('objects')
local observers = require('observers')

local conf = {
    dt = 1e-3,
    eps = 1e-6,
    nbl = neighborlist.CellNeighborlist(objects.Box({0, 0}, {1, 1}), {100, 100}),
    forces = {forces.force_gravity},
    particles = {objects.SingleParticle({0.501, 0.85}, {0.3, 0}, {0, 0})},
    objects = {
        objects.Box({0, 0}, {1, 1}),
        objects.Box({.1, .1}, {.2, .2})
    },
    observers = {
        --observers.TimePrinter(1e6)
    },
}

local s = ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e7)
local t_end = os.clock()
print(t_end - t_start)
