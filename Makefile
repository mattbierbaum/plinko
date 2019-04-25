LJ=luajit

LUA_INC = ~/builds/LuaJIT-2.1.0-beta3/src/
LUA_LIB = ~/builds/LuaJIT-2.1.0-beta3/src/libluajit.a

LIB_SRC = $(wildcard plinko/*.lua)
LIB_SRC += lib/dkjson.lua lib/argparse.lua
LIB_OBJ = $(LIB_SRC:.lua=.o)
LIB = plinko.a

EXE_SRC = $(wildcard examples/*.lua)
EXE_SRC = bin/plinko.lua
EXE_C = $(EXE_SRC:.lua=.lua.c)
EXE = $(EXE_C:.lua.c=.exe)

.PHONY: all default clean

print-%  : ; @echo $* = $($*)

%.o: %.lua
	$(LJ) -b $< $@

%.a: $(LIB_OBJ)
	ar rcs $@ $^

%.exe: %.lua
	$(LJ) lib/luastatic.lua $< $(LIB_SRC) $(LUA_LIB) -I $(LUA_INC) -o $@

all: $(EXE)

default: $(EXE)

lib: $(LIB)

clean:
	rm -f $(LIB) $(LIB_OBJ) $(EXE) $(EXE_C)
