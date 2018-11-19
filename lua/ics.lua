local simulation = require('simulation')
local objects = require('objects')
local forces = require('forces')
local vector = require('vector')
local neighborlist = require('neighborlist')
local observers = require('observers')
local plotting_image = require('plotting_image')

local ics = {}

function hex_grid_circle(rows, cols, rad)
    local a = 1
    local rt3 = math.sqrt(3)

    local out = {}
    for i = 0, rows-1 do
        for j = 0, cols-1 do
            if (i*a*rt3 >= 1e-10) then
                local c = objects.Circle({j*a, i*a*rt3}, rad)
                out[#out + 1] = c
            end

            if not (j == cols - 1) then
                local c = objects.Circle({(j+0.5)*a, (i+0.5)*a*rt3}, rad)
                out[#out + 1] = c
            end
        end
    end

    return out
end

function ics.hexgrid(N, rad)
    local N = N or 4
    local rad = rad or 0.75/2

    local h = 2*N
    local w = 2*N - 1
    local obj = hex_grid_circle(N, 2*N, rad)
    local box0 = objects.Box({0, 0}, {w, h})
    local box1 = objects.Box({-0.10001, -0.10001}, {w+0.10001, h+0.10001})
    obj[#obj + 1] = box0
    return {
        dt = 1e-4,
        eps = 1e-7,
        nbl = neighborlist.CellNeighborlist(box1, {200, 200}),
        --nbl = neighborlist.NaiveNeighborlist(),
        forces = {forces.force_gravity},
        particles = {objects.PointParticle({w/2+1e-2, h-0.5}, {0, 0}, {0, 0})},
        objects = obj,
        observers = {
            --observers.StateFileRecorder('./test.csv'),
            observers.ImageRecorder('./test.img', 
                plotting_image.DensityPlot(
                    objects.Box({-0.1, -0.1}, {w+0.1, h+0.1}), 1500
                )
            ),
            observers.TimePrinter(1e6)
        },
    }
end

function ics.single_circle()
    return {
        dt = 5e-4,
        eps = 1e-6,
        nbl = neighborlist.CellNeighborlist(objects.Box({0,0}, {1,1}), {200, 200}),
        --nbl = neighborlist.NaiveNeighborlist(),
        forces = {forces.force_gravity},
        particles = {objects.PointParticle({0.51, 0.85}, {1, 0}, {0, 0})},
        objects = {objects.Circle({0.5, 0.5}, 0.45)},
        observers = {
            observers.StateFileRecorder('./test.csv'),
            observers.ImageRecorder('./test.img', 
                plotting_image.DensityPlot(
                    objects.Box({-0.1, -0.1}, {1.1, 1.1}), 5000
                )
            )
        },
    }
end

function ics.single_circle2()
    return {
        nbl = neighborlist.CellNeighborlist(
            objects.Box({-0.1, -0.1}, {1.1, 1.1}),
            {100, 100}
        ),
        dt = 1e-3,
        eps = 1e-7,
        forces = {forces.force_gravity},
        particles = {objects.PointParticle({0.011, 0.95}, {0, 0}, {0, 0})},
        objects = {
            objects.Circle({0.5, 0.5}, 0.49),
            box = objects.Box({0,0}, {1,1})
        },
        observers = {observers.StateFileRecorder('./test.csv')},
    }
end

function ics.halfmoon()
    return {
        nbl = neighborlist.CellNeighborlist(objects.Box({0,0}, {1,1}), {50, 50}),
        --nbl = neighborlist.NaiveNeighborlist(),
        forces = {forces.force_central},
        particles = {objects.PointParticle({0.71, 0.6}, {0.1, 0}, {0, 0})},
        objects = {
            objects.Circle({0.3, 0.5}, 0.25),
            objects.Circle({0.6, 0.5}, 0.025),
            objects.Circle({0.58, 0.42}, 0.010),
            objects.Circle({0.58, 0.58}, 0.010)
        }
    }
end

function ics.circle_circles(N, radmin, radmax, R)
    local N = N or 20
    local R = R or 0.5
    local radmin = radmin or 0.001
    local radmax = radmax or 0.05
    local center = {0.5, 0.5}

    local obj = {
        objects.Circle(vector.vaddv(center, {R, 0}), radmax),
        objects.Circle(vector.vaddv(center, {-R, 0}), radmin),
        --objects.Circle(center, 0.1)
    }
    for i = 1, N-1 do
        local theta = i * math.pi / N
        local pos0 = {R*math.cos(theta), R*math.sin(theta)}
        local pos1 = {R*math.cos(theta), -R*math.sin(theta)}
        local rad = i * (radmax - radmin) / N + radmin
        obj[#obj + 1] = objects.Circle(vector.vaddv(center, pos0), rad)
        obj[#obj + 1] = objects.Circle(vector.vaddv(center, pos1), rad)
    end

    return {
        --nbl = neighborlist.CellNeighborlist(objects.Box({0,0}, {1,1}), {50, 50}),
        nbl = neighborlist.NaiveNeighborlist(),
        forces = {forces.force_central},
        particles = {objects.PointParticle({0.5, 0.53}, {0.7, 0}, {0, 0})},
        objects = obj
    }
end

function ics.free_particle()
    return {
        nbl = neighborlist.NaiveNeighborlist(),
        forces = {forces.force_central},
        particles = {objects.PointParticle({0.5, 0.6}, {0, 0}, {0, 0})},
        objects = {}
    }
end

function ics.create_simulation(conf)
    local dt = conf.dt or 1e-2
    local eps = conf.eps

    local s = simulation.Simulation(dt, eps)
    for _, i in pairs(conf.forces) do
        s:add_force(i)
    end

    for _, i in pairs(conf.objects) do
        s:add_object(i)
    end

    for _, i in pairs(conf.particles) do
        s:add_particle(i)
    end

    if conf.observers then
        for _, i in pairs(conf.observers) do
            s:add_observer(i)
        end
    end

    s:set_neighborlist(conf.nbl)
    s:initalize()
    return s
end

return ics
