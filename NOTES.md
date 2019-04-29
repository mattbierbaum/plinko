https://github.com/hugomg/lua-aot

https://repo.or.cz/w/luajit-2.0.git/blob_plain/v2.1:/doc/ext_profiler.html#jit_zone
fengari.io

* fix segment drawing
* ending conditions
* particle distributions
* more flexible interaction (damping etc)
svg input


#================================================

Translate all of the Lua source code files to object files and put them in a static library:

for f in *.lua; do
    luajit -b $f `basename $f .lua`.o
done
ar rcus libmyluafiles.a *.o

Then link the libmyluafiles.a library into your main program using -Wl,--whole-archive -lmyluafiles -Wl,--no-whole-archive -Wl,-E.
This line forces the linker to include all object files from the archive and to export all symbols.
For example, a file named foo.lua can now be loaded with local foo = require("foo") from within your application.
Details about the -b option can be found on Running LuaJIT.

#==============================================

uses that I want to cover:

record only tracks that end with a certain interrupt (fitler function??)
syphon data from a stream (filter again?)

simstate -> filter1 -> recorder1
         -> filter2 -> recorder23
         \  filter3 /

Currently, we have:

simstate -> filter(all positions) -> csv
         -> filter(all segments) -> svg
         -> filter(all segments) -> pgm
         -> filter(all segments) -> bin

What we want:

simstate -> filter(initial position) -> valueplotter -> (eqhist -> inferno -> pgm5)
         -> filter(nbounces) --------/

simstate -> filter(initial position) -> eachframe -> valueplotter -> (norm -> gray -> pgm5)
         -> filter(nbounces) --------/

simstate -> filter(pos @ time t) -> valueplotter -> norm -> gray -> pgm5
         -> filter(kinetic energy) /

Terminology:

observer is a set of streams going to a recorder
interrupt is strictly local? so no stream? yes.
