local ics = require('ics')
local objects = require('objects')
local forces = require('forces')
local neighborlist = require('neighborlist')
local observers = require('observers')
local interrupts = require('interrupts')

local N = 4
local rad = 0.5

function rotated_octagon(pos, rad)
    return ics.obj_funcs.ngon(pos, rad, 8):rotate(math.pi/8)
end

local obj, bd = ics.hex_grid_object(N, 2*N, rotated_octagon, rad)
local box0 = objects.Box(bd)
local box1 = objects.Box({bd[1], bd[2]*1.3})
obj[#obj + 1] = box0

local h = bd[2]
local w = bd[1]

local conf = {
    dt = 1e-3,
    eps = 1e-4,
    nbl = neighborlist.CellNeighborlist(box1, {200, 200}, 1e-1),
    forces = {forces.force_gravity},
    particles = {objects.PointParticle({w/2, h-0.5}, {0.1, 0}, {0, 0})},
    objects = obj,
    observers = {
        observers.StateFileRecorder('./test.csv'),
        --observers.ImageRecorder('./test.img', 
        --    plotting_image.DensityPlot(box1, 100)
        --),
        observers.TimePrinter(1e6),
        interrupts.Collision(box0.segments[4])
    },
}

local s = ics.create_simulation(conf)
s:step(5e6)
