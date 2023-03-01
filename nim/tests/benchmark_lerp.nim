import std/times
import std/strformat

proc benchmark(f: proc (): (string, int, float)): void =
    let t_start = times.cpuTime()
    let (name, steps, marker) = f()
    let t_end = times.cpuTime()
    let time = t_end - t_start
    let msg = fmt"{steps.float / time / 1e6} million steps per second ({time} seconds) ({marker})"
    echo fmt"{name}: {msg}"

type Vec* = array[2, float]
type
    Container = object
        v*: Vec

proc `+`*(v: Vec, u: Vec): Vec {.inline.} = [v[0] + u[0], v[1] + u[1]]
proc `*`*(v: Vec, s: float): Vec {.inline.} = [v[0] * s, v[1] * s]
proc `*`*(s: float, v: Vec): Vec {.inline.} = v * s
proc lerp*(v0: Vec, v1: Vec, t: float): Vec {.inline.} = (1.0 - t)*v0 + t*v1

proc lerp_simple(): (string, int, float) =
    var sum = 0.0
    let steps = 1e8.int

    let v0 = [0.0, 0.0]
    let v1 = [1.0, 1.0]
    for i in 0 .. steps:
        let p = lerp(v0, v1, 0.5)
        sum = sum + p[0]
    return ("lerp_simple", steps, sum)

proc lerp_object(): (string, int, float) =
    var sum = 0.0
    let steps = 1e8.int

    var o0 = Container(v: [0.0, 0.0])
    var o1 = Container(v: [1.0, 1.0])
    for i in 0 .. steps:
        o0.v = lerp(o0.v, o1.v, 0.5)
        sum = sum + o0.v[0]
    return ("lerp_object", steps, sum)

benchmark(lerp_simple)
benchmark(lerp_object)
