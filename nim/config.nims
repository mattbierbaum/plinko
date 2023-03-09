proc set_common_options(): void =
  switch("threads", "on")
  switch("threadAnalysis", "off")
  switch("opt", "speed")
  switch("gc", "markAndSweep")
  switch("passC", "-flto")
  switch("passL", "-s")
  switch("passL", "-static")

task release, "build standard release":
  set_common_options()
  switch("d", "release")
  setCommand "c", "plinko.nim"

task musl, "build musl release":
  set_common_options()
  switch("d", "release")
  switch("gcc.exe", "musl-gcc")
  switch("gcc.linkerexe", "musl-gcc")
  setCommand "c", "plinko.nim"

task debug, "build debug":
  set_common_options()
  switch("d", "debug")
  setCommand "c", "plinko.nim"

task profile, "build profilable":
  set_common_options()
  switch("d", "debug")
  switch("profiler", "on")
  switch("stacktrace", "on")
  setCommand "c", "plinko.nim"

task js, "build javascript version":
  switch("d", "release")
  switch("o", "web/js.js")
  setCommand "js", "js.nim"