#!/bin/bash
gcc -I ~/builds/LuaJIT-2.1.0-beta3/src -ansi -Wall -O2 -fPIC -shared -o plotting.so plotting.c
