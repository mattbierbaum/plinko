local ics = require('ics')

s = ics.create_simulation(ics.halfmoon())

t_start = os.clock()
s:step(1000000)
t_end = os.clock()
print(t_end - t_start)
