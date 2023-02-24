import objects
import forces
import neighborlist
import observers
import interrupts
import simulation


var sim: Simulation = Simulation().initSimulation()
var particle = PointParticle(
    pos: [0.5, 0.5],
    vel: [0.0, 0.0],
    acc: [0.0, 0.0])
var group = SingleParticle().initSingleParticle(particle)
sim.add_particle(group)
sim.add_object(Box().initBox(ll=[0.0, 0.0], uu=[1.0, 1.0]))
sim.add_force(generate_force_gravity(-1))
sim.add_observer(TimePrinter())
sim.add_observer(MaxSteps(max: 10.0))
sim.set_neighborlist(Neighborlist())

sim.initialize()
sim.step(10)