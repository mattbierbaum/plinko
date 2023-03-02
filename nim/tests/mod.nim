import std/strformat

let a = 13
for i in 0..100:
    echo fmt"{i} {a} {i mod a} {i mod a == 0}"
