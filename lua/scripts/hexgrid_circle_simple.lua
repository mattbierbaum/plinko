function ics.hexgrid(N, rad)
    local N = N or 4
    local rad = rad or 0.75/2

    local h = 2*N
    local w = 2*N - 1
    local M = math.max(h, w)
    local obj = hex_grid_circle(N, 2*N, rad)
    local box0 = objects.Box({0, 0}, {w, h})
    local box1 = objects.Box({0, 0}, {M, M})
    obj[#obj + 1] = box0
    return {
        dt = 1e-3,
        eps = 1e-6,
        nbl = neighborlist.CellNeighborlist(box1, {200, 200}),
        forces = {forces.force_gravity},
        particles = {objects.PointParticle({w/2+1e-2, h-0.5}, {0, 0}, {0, 0})},
        objects = obj,
        observers = {
            observers.StateFileRecorder('./test.csv'),
            --observers.ImageRecorder('./test.img', 
            --    plotting_image.DensityPlot(box1, 100)
            --),
            observers.TimePrinter(1e6)
        },
    }
end


