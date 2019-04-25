local P = require('plinko')

function column_squares(N, theta0, theta1, gap_top, gap_side)
    local size = 1.0
    local vdiag = {1.0*size/2, size/2}
    local xcom = size / 2 + gap_side

    local obj = {}
    for i = 1, N do
        local theta = (theta1 - theta0) * (i-1) / (N-1) + theta0
        local com = {xcom, (i-1)*(size + gap_side) + gap_top}
        local ll = P.vector.vsubv(com, vdiag)
        local uu = P.vector.vaddv(com, vdiag)
        local box = P.objects.Rectangle(ll, uu):rotate(theta)

        local bbox = box:coordinate_bounding_box()
        local hlength = bbox[2][1] - bbox[1][1]
        box = box:scale(2*size / hlength)
        obj[#obj + 1] = box
    end

    local obj_maxx = obj[#obj]:center()[1]
    local obj_maxy = obj[#obj]:center()[2]

    local container = P.objects.Rectangle(
        {0, 0}, {size + 2*gap_side, (obj_maxy + size/2 + gap_top)}
    )
    return obj, container
end

local obj, container = column_squares(7, -math.pi/4, math.pi/4, 1.0, 0.0135)
local top_center = {container:center()[1], container:coordinate_bounding_box()[2][2]}

obj[#obj + 1] = container

local bbox = container:coordinate_bounding_box()
local box = P.objects.Box(bbox[1], bbox[2])

local conf = {
    dt = 1e-3,
    eps = 1e-5,
    nbl = P.neighborlist.CellNeighborlist(box, {200, 200}, 1e-1),
    forces = {P.forces.generate_force_central({top_center[1], top_center[2]/2}, 2.0)},
    particles = {P.objects.SingleParticle(P.vector.vaddv(top_center, {0.0, -0.2}), {0.5, 0}, {0, 0})},
    objects = obj,
    observers = {
        P.observers.StateFileRecorder('./test.csv'),
        P.observers.TimePrinter(1e6)
    },
}

local s = P.ics.create_simulation(conf)
local t_start = os.clock()
s:step(1e6)
local t_end = os.clock()
print(t_end - t_start)
