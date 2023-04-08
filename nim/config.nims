import std/os
import std/sequtils
import std/strutils

const 
  output = "build/plinko"
  main = "plinko/plinko.nim"
  js = "plinko/js.nim"

proc set_common_options(): void =
  switch("threads", "on")
  switch("threadAnalysis", "off")
  switch("opt", "speed")
  switch("gc", "arc")
  switch("o", output)

task release, "build standard release":
  set_common_options()
  switch("stackTrace", "off")
  switch("d", "release")
  switch("passC", "-flto")
  switch("passL", "-s")
  switch("passL", "-static")
  setCommand "c", main

task danger, "built for speed":
  set_common_options()
  switch("stackTrace", "off")
  switch("d", "danger")
  switch("passC", "-flto -ffast-math -march=native")
  #switch("passC", "-ffast-math")
  #switch("passC", "-march=native")
  switch("passL", "-s")
  switch("passL", "-static")
  switch("checks", "off")
  switch("panics", "on")
  setCommand "c", main

task musl, "build musl release":
  set_common_options()
  switch("d", "release")
  switch("gcc.exe", "musl-gcc")
  switch("gcc.linkerexe", "musl-gcc")
  setCommand "c", main

task debug, "build debug":
  set_common_options()
  switch("d", "debug")
  setCommand "c", main

# echo "1" | sudo tee /proc/sys/kernel/perf_event_paranoid 
# perf record -o original.data --call-graph dwarf -- plinko json
# perf stat -e task-clock,cycles,instructions,cache-references,cache-misses plinko json
# perf record -e cache-misses
task flame, "build flame profile":
  set_common_options()
  switch("stackTrace", "off")
  switch("passC", "-Og -ggdb -g3 -fno-omit-frame-pointer")
  setCommand "c", main

task profile, "build profilable":
  set_common_options()
  # switch("d", "debug")
  switch("profiler", "on")
  switch("stacktrace", "on")
  setCommand "c", main

task memprofile, "build mem-profilable":
  set_common_options()
  switch("profiler", "off")
  switch("stacktrace", "on")
  switch("d", "memProfiler")
  setCommand "c", main

task js, "build javascript version":
  switch("d", "release")
  switch("o", "web/js.js")
  setCommand "js", js

task test, "Run tests in tests/ dir":
  let
    testDir = "tests"
  if dirExists(testDir):
    let
      testFiles = listFiles(testDir).filterIt(it.endsWith(".nim") and it.startsWith("test_"))
    for t in testFiles:
      selfExec "c -r " & t
