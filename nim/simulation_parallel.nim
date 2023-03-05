import std/threadpool
{.experimental: "parallel".}

import objects
import simulation

proc partition*(self: Simulation): seq[Simulation] =
    var sims: seq[Simulation] = @[]
    var particles : seq[seq[ParticleGroup]] = @[]

    for i in 0 .. self.threads:
        particles.add(@[])
        sims.add(deepCopy(self))
        sims[i].particle_groups = @[]

    for grp in self.particle_groups:
        let grps = grp.partition(self.threads)
        for i, g in grps:
            sims[i].add_particle(g)

    return sims

proc join*(sims: seq[Simulation]): Simulation =
    return sims[0]

proc run_parallel*(self: Simulation): Simulation =
    if self.threads == 1:
        self.run()
        return self

    var sims: seq[Simulation] = self.partition()
    parallel:
        for sim in sims:
            spawn sim.run()
    return join(sims)