local P = require('plinko')
local argparse = require('lib.argparse')

local damp = 1.0
local D = 0.05
local box = P.objects.Box({0, 0}, {1, 1})
local line = P.objects.Segment({D, 0.3}, {1-D, 0.7}, {damp=damp})
local circle = P.objects.Circle({0.5, 0.5}, 0.1, {damp=damp})

local opt = argparse(){name='test'}
P.cli.options_observer(opt, 'test.pgm', '4e3')
P.cli.options_particles(opt, {0.5,0.9}, {0,0}, 'single')
local arg = opt:parse(arg)

local conf = {
    dt = 5e-2,
    eps = 1e-8,
    objects = {box, line, circle},
    forces = {P.forces.force_gravity},
    particles = {P.cli.args_to_particles(arg)},
    observers = {
        P.cli.args_to_observer(arg, box),
        P.observers.TimePrinter(1e6),
        P.interrupts.Collision(box.segments[4])
    },
}

P.ics.create_simulation(conf):step(1e7)
