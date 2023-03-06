# import nimprof

import ics
import simulation
import objects
import observers
import observers_native

import std/cpuinfo
import std/os
import std/strformat
import std/times

import std/threadpool
{.experimental: "parallel".}

proc combine*(self: ObserverGroup, other: ObserverGroup): ObserverGroup =
    for i, obs0 in self.observers:
        for j, obs1 in other.observers:
            if obs0 of NativeImageRecorder and obs1 of NativeImageRecorder:
                self.observers[i] = obs0.NativeImageRecorder + obs1.NativeImageRecorder
    return self

proc duplicate_for_thread*(self: Simulation): Simulation =
    var s = Simulation().initSimulation()
    s.dt = self.dt
    s.eps = self.eps
    s.max_steps = self.max_steps
    s.threads = self.threads
    s.verbose = self.verbose
    s.linear = self.linear
    s.equal_time = self.equal_time
    s.accuracy_mode = self.accuracy_mode
    s.record_objects = self.record_objects
    s.particle_index = 0
    s.particle_groups = @[]
    s.observer_group = self.observer_group.duplicate().ObserverGroup
    s.observers = self.observer_group.observers
    s.force_func = deepCopy(self.force_func)
    s.integrator = deepCopy(self.integrator)
    s.objects = deepCopy(self.objects)
    s.nbl = deepCopy(self.nbl)
    return s

proc partition*(self: Simulation): seq[Simulation] =
    var sims: seq[Simulation] = @[]

    for i in 0 .. self.threads-1:
        sims.add(self.duplicate_for_thread())

    for grp in self.particle_groups:
        let grps = grp.partition(self.threads)
        for i, g in grps:
            sims[i].add_particle(g)

    return sims

proc join*(sims: seq[Simulation]): Simulation =
    for i in 1 .. sims.len-1:
        sims[0].observer_group = sims[0].observer_group.combine(sims[i].observer_group)
    return sims[0]

proc run_parallel*(self: Simulation): Simulation =
    if self.threads == 1:
        return self.run()

    if self.threads <= 0:
        self.threads = countProcessors()

    echo "Partitioning..."
    var sims = self.partition()
    var flowsims: seq[FlowVar[Simulation]] = @[]

    echo "Launching..."
    parallel:
        for i, sim in sims:
            flowsims.add(spawn sim.run())
    sync()

    echo "Copying results..."
    var newsims: seq[Simulation] = @[]
    for flow in flowsims:
        newsims.add(^flow)

    echo "Joining..."
    var o = join(newsims)
    echo "Done."
    return o

let params = commandLineParams()
if len(params) != 1:
    echo "Usage: plinko <simulation.json>"
else:
    let json = open(params[0], fmRead).readAll()
    var sim = json_to_simulation(json)
    sim.initialize()

    if sim.verbose:
        echo $sim

    var time_start = times.cpuTime()
    sim = sim.run_parallel()
    var time_end = times.cpuTime()
    let particle_steps = sim.particle_index.float * sim.max_steps.float
    echo fmt"Step rate (M/sec): {particle_steps/(time_end-time_start)/1e6}"

    time_start = times.cpuTime()
    sim.close()
    time_end = times.cpuTime()
    echo fmt"Close time (sec): {time_end - time_start}"

    clear_warning()