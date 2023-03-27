when compileOption("profiler"):
    import nimprof

import ics
import simulation
import observers_native

import std/cpuinfo
import std/os
import std/strformat
import std/strutils
import std/times
import std/threadpool

proc transform_json(json: string, subs: string): string =
    var o = json
    for sub in subs.split(","):
        if not sub.contains("="):
            continue
        var (key, value) = (sub.split("=")[0], sub.split("=")[1])
        o = o.replace(fmt"${key}", value)
    return o

proc get_threads(json: string): int =
    var threads = json_to_threads(json)
    if threads <= 0:
        threads = countProcessors()
    return threads

proc join(sims: seq[Simulation]): Simulation =
    for i in 1 .. sims.len-1:
        sims[0].observer_group = sims[0].observer_group.combine(sims[i].observer_group)
        sims[0].particle_steps = sims[0].particle_steps + sims[i].particle_steps
    return sims[0]

proc run(json: string, index: int=0): Simulation =
    var sim = json_to_simulation(json, index)
    sim.initialize()

    if sim.verbose and index == 0:
        echo $sim

    sim.run()
    sim.clear_intermediates()
    return sim

proc run_parallel(json: string): Simulation =
    echo "Launching parallel..."
    let threads = get_threads(json)
    var flowsims: seq[FlowVar[Simulation]] = @[]
    for i in 0 .. threads-1:
        flowsims.add(spawn run(json, i))
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
if len(params) < 1:
    echo "Usage: plinko <simulation.json> \"replacement=value,other=othervalue\""
else:
    echo fmt"Args: {params}"
    var subs = ""
    if len(params) == 2:
        subs = params[1]
    var json = transform_json(open(params[0], fmRead).readAll(), subs)
    let threads = get_threads(json)

    var time_start = times.getTime()
    var sim: Simulation = nil
    if threads == 1:
        sim = run(json)
    else:
        sim = run_parallel(json)
    var time_end = times.getTime()
    var dt = (time_end - time_start).inNanoseconds.float / 1e9
    echo fmt"Step rate (M/sec): {sim.particle_steps.float/dt/1e6} ({dt} sec)"

    time_start = times.getTime()
    sim.close()
    time_end = times.getTime()
    dt = (time_end - time_start).inNanoseconds.float / 1e9
    echo fmt"Close time (sec): {dt}"