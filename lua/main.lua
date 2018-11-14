local ics = require('ics')

s = ics.create_simulation(ics.circle_circles()):step(1000000)
