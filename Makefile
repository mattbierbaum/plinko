CC=gcc
LJ=luajit

LUA_INC = ~/builds/LuaJIT-2.1.0-beta3/src/
LUA_LIB = ~/builds/LuaJIT-2.1.0-beta3/src/libluajit.a

EXDIR = examples
PACKAGED_SCRIPTS = $(EXDIR)/column_of_squares.lua
PACKAGED_SCRIPTS += $(EXDIR)/concentric_circles.lua
PACKAGED_SCRIPTS += $(EXDIR)/curtains.lua
PACKAGED_SCRIPTS += $(EXDIR)/hearrt.lua
PACKAGED_SCRIPTS += $(EXDIR)/hexgrid_huge_circle.lua
PACKAGED_SCRIPTS += $(EXDIR)/orbits.lua
PACKAGED_SCRIPTS += $(EXDIR)/snowflakes.lua
PACKAGED_SCRIPTS += $(EXDIR)/speedtest.lua

LIB_SRC = $(wildcard plinko/*.lua) $(wildcard lib/*.lua) $(PACKAGED_SCRIPTS)
LIB_OBJ = $(LIB_SRC:.lua=.o)
LIB = plinko.a
SO = plinko.so

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

%.so: $(LIB_OBJ)
	$(CC) -shared $^ -o $@

%.exe: %.lua
	$(LJ) lib/luastatic.lua $< $(LIB_SRC) $(LUA_LIB) -I $(LUA_INC) -o $@

all: $(EXE)

default: $(EXE)

lib: $(LIB)

shared: $(SO)

clean:
	rm -f $(LIB) $(LIB_OBJ) $(EXE) $(EXE_C)
