# import nimprof
import ../objects
import ../forces
import ../simulation

let steps = 10
var particle = PointParticle().initPointParticle(
    pos=[0.5, 0.001],
    vel=[0.0, -0.000123],
    acc=[0.0, 0.0])
var particle_group = SingleParticle().initSingleParticle(particle)
var box = Box().initBox(ll=[0.0, 0.0], uu=[1.0, 1.0], damp=1.0)

var sim: Simulation = Simulation().initSimulation(max_steps=steps)
sim.eps = 1e-10
sim.accuracy_mode = true
sim.add_particle(particle_group)
sim.add_object(box)
sim.add_force(generate_force_gravity(-1))
sim.initialize()

echo $sim
sim.run()