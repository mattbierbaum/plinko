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