local ics = require('ics')
local objects = require('objects')
local forces = require('forces')
local neighborlist = require('neighborlist')
local observers = require('observers')
local interrupts = require('interrupts')
local plotting_image = require('plotting_image')
local util = require('util')

local N = 100
local O = 4
local rad = 0.49
local damp = 1.0

function rotated_octagon(pos, rad)
    return ics.obj_funcs.ngon(pos, rad, 8, {damp=damp}):rotate(math.pi/12)
end

local obj, bd = ics.hex_grid_object(O, 2*O, rotated_octagon, rad)
local max = math.max(bd[1], bd[2]*1.3)
local box0 = objects.Box({0, 0}, bd)
local box1 = objects.Box({0, 0}, {bd[1], bd[2]*1.3})
local box2 = objects.Box({0, 0}, {max, max})
obj[#obj + 1] = box0

util.tprint(obj)
local h = bd[2]
local w = bd[1]

local conf = {
    dt = 1e-2,
    eps = 1e-4,
    --nbl = neighborlist.CellNeighborlist(box1, {200, 200}, 1e-1),
    forces = {forces.force_gravity},
    particles = {
        objects.SingleParticle({w/2, h-0.5}, {0.1, 0}, {0, 0}),
        objects.UniformParticles(
            {w/2-0.1, h-0.5}, {w/2+0.1, h-0.5},
            {0.1, 0.0}, {0.1, 0.0}, N
        )
    },
    objects = obj,
    observers = {
        --observers.StateFileRecorder('./test.csv'),
        observers.ImageRecorder('./test.img', 
            plotting_image.DensityPlot(box2, 200)
        ),
        observers.TimePrinter(1e6),
        interrupts.Collision(box0.segments[4])
    },
}

local s = ics.create_simulation(conf)
s:step(5e6)
