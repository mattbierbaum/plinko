# import nimprof
import ../objects
import ../forces
import ../neighborlist
import ../observers
import ../particles
import ../simulation

import std/strformat
import std/times

let steps = 100000
var particle = PointParticle().initPointParticle(
    pos=[0.5, 0.9],
    vel=[0.2111, 1.0],
    acc=[0.0, 0.0])
var particle_group = SingleParticle().initSingleParticle(particle)
var box = Box().initBox(ll=[0.0, 0.0], uu=[1.0, 1.0], damp=0.9999)
var rot = Box().initBox(ll=[0.1, 0.1], uu=[0.2, 0.2], damp=0.9999)
var circle = Circle().initCircle(pos=[0.5, 0.5], rad=0.2)
var nbl = CellNeighborlist().initCellNeighborlist(box=box, ncells=[50,50], buffer=0.2)
var svg = SVGLinePlot().initSVGLinePlot(filename="test.svg", box=box, lw=0.000001)

var sim: Simulation = Simulation().initSimulation(max_steps=steps)
sim.add_particle(particle_group)
sim.add_object(box)
sim.add_object(rot)
sim.add_object(circle)
sim.add_force(generate_force_gravity(-1))
sim.set_neighborlist(nbl)
sim.add_observer(svg)

#[
var plot = DensityPlot().initDensityPlot(box=box, dpi=100, blendmode=blendmode_additive)
var imgobs = ImageRecorder().initImageRecorder(
        filename="test.pgm",
        plotter=plot,
        format="pgm5",
        cmap=gray_r,
        norm=eq_hist)
sim.add_observer(imgobs)
]#

sim.initialize()

echo $sim

let time_start = times.cpuTime()
sim.run()
let time_end = times.cpuTime()
echo fmt"Rates (Mstep/sec): {steps.float/(time_end-time_start)/1e6}"