switch("d", "release")
switch("threads", "on")
switch("threadAnalysis", "off")
switch("opt", "speed")
switch("gc", "markAndSweep")
switch("passC", "-flto")
switch("passL", "-s")
switch("passL", "-static")

when defined(testing) :
  switch("verbosity", "1")
  switch("hints", "on")

#
# Tasks
#
task build, "build project":
  exec "nim c plinko.nim"

task debug, "build debug":
  switch("d", "debug")
  exec "nim c plinko.nim"
