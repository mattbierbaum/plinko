local conf = {
    nbl = neighborlist.NaiveNeighborlist(),
    forces = {forces.force_central},
    particles = {objects.PointParticle({0.5, 0.6}, {0, 0}, {0, 0})},
    objects = {}
}

