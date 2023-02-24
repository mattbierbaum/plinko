import objects
import forces
import neighborlist
import observers
import interrupts
import simulation
import plotting

var sim: Simulation = Simulation().initSimulation()
var particle = PointParticle().initPointParticle(
    pos=[0.5, 0.001],
    vel=[0.0, 0.0],
    acc=[0.0, 0.0])
var particle_group = SingleParticle().initSingleParticle(particle)

var box = Box().initBox(ll=[0.0, 0.0], uu=[1.0, 1.0], damp=1.0)
sim.add_particle(particle_group)
sim.add_object(box)
sim.add_force(generate_force_gravity(-1))
sim.add_observer(TimePrinter())
sim.add_observer(MaxSteps(max: 10.0))
sim.set_neighborlist(Neighborlist())

#var plot = DensityPlot().initDensityPlot(box=box, dpi=100, blendmode=blendmode_additive)

sim.initialize()
sim.step(100)