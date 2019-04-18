LJ=luajit

LIB_SRC = $(wildcard *.lua)
LIB_OBJ = $(LIB_SRC:.lua=.o)
LIB = plinko.a

INC = /usr/local/include
EXE_SRC = $(wildcard scripts/*.lua)
EXE_C = $(EXE_SRC:.lua=.lua.c)
EXE = $(EXE_C:.lua.c=.exe)

.PHONY: all default clean

print-%  : ; @echo $* = $($*)

%.o: %.lua
	$(LJ) -b $< $@

%.a: $(LIB_OBJ)
	ar rcs $@ $^

%.exe: %.lua $(LIB)
	$(LJ) external/luastatic.lua $< $(LIB_SRC) ~/builds/LuaJIT-2.0.5/src/libluajit.a $(LIB) -static -ldl -no-pie -o $@

all: $(EXE)

default: $(EXE)

lib: $(LIB)

clean:
	rm -f $(LIB) $(LIB_OBJ) $(EXE) $(EXE_C)
