import objects
import forces
import neighborlist
import observers
import interrupts
import simulation

var sim: Simulation = Simulation().initSimulation()
var particle = PointParticle().initPointParticle(
    pos=[0.5, 0.9],
    vel=[0.2111, 1.0],
    acc=[0.0, 0.0])
var particle_group = SingleParticle().initSingleParticle(particle)
var box = Box().initBox(ll=[0.0, 0.0], uu=[1.0, 1.0], damp=1.0)
var circle = Circle().initCircle(pos=[0.5, 0.5], rad=0.2)

sim.add_particle(particle_group)
sim.add_object(box)
sim.add_object(circle)
sim.add_force(generate_force_gravity(-1))
#sim.add_observer(TimePrinter())
#sim.add_observer(MaxSteps(max: 10.0))
sim.set_neighborlist(Neighborlist())

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

var svg = SVGLinePlot().initSVGLinePlot(filename="test.svg", box=box, lw=0.00001)
sim.add_observer(svg)

sim.initialize()
sim.step(10000)