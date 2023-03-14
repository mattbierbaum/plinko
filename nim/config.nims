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
  switch("gc", "markAndSweep")
  switch("passC", "-flto")
  #switch("passL", "-s")
  #switch("passL", "-static")
  switch("o", output)

task release, "build standard release":
  set_common_options()
  switch("d", "release")
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

task profile, "build profilable":
  set_common_options()
  # switch("d", "debug")
  switch("profiler", "on")
  switch("stacktrace", "on")
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
