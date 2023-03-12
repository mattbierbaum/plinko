PLINKO
======

There are several implementations here:

* **c** -- older c implementation with internal and python plotting
* **lua** -- newer lua implementation that plots internally
* **nim** -- newest nim implementation, feature parity with lua

C
---

The C version if compiled with `make` in the `c` directory.

Lua
---

The lua version may be run in place with luajit or statically compiled
into a binary that includes all lua source and luajit itself. To compile,
run `make` in the lua subdirectory. Beforehand, you must download 
LuaJIT >= 2.1.0-beta3 and point the `LUA_INC` and `LUA_LIB` to the install
directory within the `Makefile`.

Nim
---

To compile the nim version, cd to the directory and run `nim release`
to create the statically compiled binary. Then, it may be run using
`plinko <name-of-coniguration.json>`. To create the web version,
run `nim js` within the nim directory. It may be self-hosted by
running `python -m http.server` within the `nim/web` directory.