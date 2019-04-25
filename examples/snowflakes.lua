local ics = require('ics')
local objects = require('objects')
local forces = require('forces')
local neighborlist = require('neighborlist')
local observers = require('observers')
local interrupts = require('interrupts')
local plotting_image = require('plotting_image')
local util = require('util')

local O = 20
local rad = 0.5001
local cargs = {damp=1.0}

function masked_circle(p, r, N, eps, offset)
    return objects.MaskedCircle(p, r,
        objects.circle_masks.circle_nholes(N, eps, offset),
        cargs
    )
end

local obj, bd = ics.hex_grid_object(O, O, masked_circle, rad, 6, 2e-3, 0)
local w, h = bd[1], bd[2]
local view = {bd[1], bd[2]*1.3}
local max = math.max(view[1], view[2])

local box0 = objects.Box({0, 0}, bd)
local box1 = objects.Box({0, 0}, bd)
local box2 = objects.Box({0, 0}, {max, max})
obj[#obj + 1] = box0

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    nbl = neighborlist.CellNeighborlist(box1, {200, 200}, 1e-1),
    forces = {forces.force_gravity},
    --particles = {objects.SingleParticle({w/2, h-0.5}, {0.1, 0}, {0, 0})},
    particles = {objects.SingleParticle({9.4, 33.8}, {0.0, 0}, {0, 0})},
    objects = obj,
    observers = {
        observers.StateFileRecorder('./test.csv'),
        observers.TimePrinter(1e4),
        interrupts.Collision(box0.segments[4])
    },
}

local s = ics.create_simulation(conf)
s:step(1e6)
