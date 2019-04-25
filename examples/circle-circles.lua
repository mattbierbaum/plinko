local P = require('plinko')

function circle_circles(N, radmin, radmax, R)
    local N = N or 20
    local R = R or 0.5
    local radmin = radmin or 0.001
    local radmax = radmax or 0.05
    local center = {0.5, 0.5}

    local obj = {
        P.objects.Circle(P.vector.vaddv(center, {R, 0}), radmax),
        P.objects.Circle(P.vector.vaddv(center, {-R, 0}), radmin),
        --objects.Circle(center, 0.1)
    }
    for i = 1, N-1 do
        local theta = i * math.pi / N
        local pos0 = {R*math.cos(theta), R*math.sin(theta)}
        local pos1 = {R*math.cos(theta), -R*math.sin(theta)}
        local rad = i * (radmax - radmin) / N + radmin
        obj[#obj + 1] = P.objects.Circle(P.vector.vaddv(center, pos0), rad)
        obj[#obj + 1] = P.objects.Circle(P.vector.vaddv(center, pos1), rad)
    end

    return {
        --nbl = neighborlist.CellNeighborlist(objects.Box({0,0}, {1,1}), {50, 50}),
        nbl = P.neighborlist.NaiveNeighborlist(),
        forces = {P.forces.generate_force_central({0, 0}, -1.0)},
        particles = {P.objects.SingleParticle({0.5, 0.53}, {0.7, 0}, {0, 0})},
        objects = obj
    }
end

local s = P.ics.create_simulation(circle_circles())
s:step(1e5)
