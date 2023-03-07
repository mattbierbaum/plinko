# import nimprof

import ics
import simulation
import observers
import observers_native

import std/cpuinfo
import std/os
import std/strformat
import std/times

import std/threadpool
{.experimental: "parallel".}

proc get_threads*(json: string): int =
    var threads = json_to_threads(json)
    if threads <= 0:
        threads = countProcessors()
    return threads

proc create_and_run*(json: string, index: int): Simulation =
    var sim = json_to_simulation(json, index)
    sim.initialize()
    sim.run()
    return sim

proc combine*(self: ObserverGroup, other: ObserverGroup): ObserverGroup =
    for i, obs0 in self.observers:
        for j, obs1 in other.observers:
            if obs0 of NativeImageRecorder and obs1 of NativeImageRecorder:
                self.observers[i] = obs0.NativeImageRecorder + obs1.NativeImageRecorder
    return self

proc join*(sims: seq[Simulation]): Simulation =
    for i in 1 .. sims.len-1:
        sims[0].observer_group = sims[0].observer_group.combine(sims[i].observer_group)
    return sims[0]

proc run*(json: string): Simulation =
    var sim = json_to_simulation(json)
    sim.initialize()

    if sim.verbose:
        echo $sim

    sim.run()
    return sim

proc run_parallel*(json: string): Simulation =
    echo "Launching parallel..."
    let threads = get_threads(json)
    var flowsims: seq[FlowVar[Simulation]] = @[]
    parallel:
        for i in 0 .. threads-1:
            flowsims.add(spawn create_and_run(json, i))
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
    let threads = get_threads(json)

    var time_start = times.cpuTime()
    var sim: Simulation = nil
    if threads == 1:
        sim = run(json)
    else:
        sim = run_parallel(json)
    var time_end = times.cpuTime()
    let particle_steps = sim.particle_index.float * sim.max_steps.float
    echo fmt"Step rate (M/sec): {particle_steps/(time_end-time_start)/1e6}"

    time_start = times.cpuTime()
    sim.close()
    time_end = times.cpuTime()
    echo fmt"Close time (sec): {time_end - time_start}"