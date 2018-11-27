local simulation = require('simulation')
local objects = require('objects')
local forces = require('forces')
local vector = require('vector')
local neighborlist = require('neighborlist')
local observers = require('observers')
local plotting_image = require('plotting_image')
local util = require('util')

local ics = {}
ics.obj_funcs = {}

function ics.obj_funcs.circle(pos, rad, cargs)
    return objects.Circle(pos, rad, cargs)
end

function ics.obj_funcs.ngon(pos, size, N, cargs)
    return objects.RegularPolygon(N, pos, size, cargs)
end

function ics.hex_grid_object(rows, cols, func, ...)
    local a = 1
    local rt3 = math.sqrt(3)

    local out = {}
    for i = 0, rows-1 do
        for j = 0, cols-1 do
            if (i*a*rt3 >= 1e-10) then
                out[#out + 1] = func({j*a, i*a*rt3}, ...)
            end

            if not (j == cols - 1) then
                out[#out + 1] = func({(j+0.5)*a, (i+0.5)*a*rt3}, ...)
            end
        end
    end

    local boundary = {(cols-1)*a, (rows+1)*rt3*a}
    return out, boundary
end

function ics.create_simulation(conf)
    local dt = conf.dt or 1e-2
    local eps = conf.eps or 1e-6

    local s = simulation.Simulation(dt, eps)
    if conf.forces then
        for _, i in pairs(conf.forces) do
            s:add_force(i)
        end
    else
        s:add_force(forces.force_none)
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

    if conf.nbl then
        s:set_neighborlist(conf.nbl)
    else
        s:set_neighborlist(neighborlist.NaiveNeighborlist())
    end

    s:initalize()
    return s
end

return ics
