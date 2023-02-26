#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>
#include <stdio.h>

int main(void)
{
    int status, result, i;
    lua_State *L;

    L = luaL_newstate();

    luaL_openlibs(L);

    /* load your lua entry point here */
    status = luaL_loadfile(L, "mainluafile.lua");
    if (status) {
        fprintf(stderr, "Couldn't load file: %s\n", lua_tostring(L, -1));
        exit(1);
    }


    result = lua_pcall(L, 0, LUA_MULTRET, 0);
    if (result) {
        fprintf(stderr, "Failed to run script: %s\n", lua_tostring(L, -1));
        exit(1);
    }

    lua_close(L);

    return 0;
}
