function ics.halfmoon()
    return {
        dt = 1e-3,
        eps = 1e-7,
        nbl = neighborlist.CellNeighborlist(objects.Box({0,0}, {1,1}), {100, 100}),
        --nbl = neighborlist.NaiveNeighborlist(),
        forces = {forces.force_central},
        particles = {objects.PointParticle({0.71, 0.6}, {0.1, 0}, {0, 0})},
        objects = {
            objects.Circle({0.3, 0.5}, 0.25),
            objects.Circle({0.6, 0.5}, 0.025),
            objects.Circle({0.58, 0.42}, 0.010),
            objects.Circle({0.58, 0.58}, 0.010)
        },
        observers = {
            observers.StateFileRecorder('./test.csv'),
            observers.TimePrinter(1e6)
        },
    }
end


