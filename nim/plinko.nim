# import nimprof

import ics
import simulation

import std/cpuinfo
import std/os
import std/strformat
import std/times

import std/threadpool
{.experimental: "parallel".}

proc run_parallel*(self: Simulation): Simulation =
    if self.threads == 1:
        return self.run()

    if self.threads <= 0:
        self.threads = countProcessors()

    echo "Partitioning..."
    var sims = self.partition()
    var flowsims = newSeq[FlowVar[Simulation]](sims.len)

    echo "Launching..."
    parallel:
        for i, sim in sims:
            flowsims[i] = spawn sim.run()
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