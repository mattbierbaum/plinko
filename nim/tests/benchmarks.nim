import ../objects
import ../roots
import ../vector

import std/times
import std/strformat

proc benchmark(f: proc (): (string, int, float)): void =
    let t_start = times.cpuTime()
    let (name, steps, marker) = f()
    let t_end = times.cpuTime()
    let time = t_end - t_start
    let msg = fmt"{steps.float / time / 1e6} million steps per second ({time} seconds) ({marker})"
    echo fmt"{name}: {msg}"

proc array_creation(): (string, int, float) =
    var sum = 0.0
    let steps = 1e8.int
    for i in 0 .. steps:
        let v = [0.0, i.float]
        sum = sum + v[1]
    return ("array_creation", steps, sum)

proc array_modification(): (string, int, float) =
    var sum = 0.0
    let steps = 1e8.int
    var v = [0.0, 0.0]
    for i in 0 .. steps:
        v[1] = i.float
        sum = sum + v[1]
    return ("array_modification", steps, sum)

proc array_addition(): (string, int, float) =
    var sum = 0.0
    let steps = 1e8.int
    var v = [0.0, 0.0]
    var w = [1.0, 1.0]
    for i in 0 .. steps:
        let s = v + w
        sum = sum + s[0] + s[1]
    return ("array_addition", steps, sum)

proc seq_creation(): (string, int, float) =
    var sum = 0.0
    let steps = 1e8.int
    for i in 0 .. steps:
        let v = @[0.0, i.float]
        sum = sum + v[1]
    return ("seq_creation", steps, sum)

proc seq_modification(): (string, int, float) =
    var sum = 0.0
    let steps = 1e7.int
    var v = @[0.0, 0.0]
    for i in 0 .. steps:
        v[1] = i.float
        sum = sum + v[1]
    return ("seq_modification", steps, sum)

proc segment_creation(): (string, int, float) =
    var sum = 0.0
    let steps = 1e8.int
    for i in 0 .. steps:
        let v = Segment().initSegment(p0=[0.0,0.0], p1=[0.0,1.0])
        sum = sum + v.p1[1]
    return ("segment_creation", steps, sum)

proc roots_quadratic(): (string, int, float) =
    var sum = 0.0
    let steps = 1e6.int
    var v = [-1.0, -1.0, 1.0]
    for i in 0 .. steps:
        sum += quadratic(v)[0]
    return ("roots_quadratic", steps, sum)

#[ This was 5x slower than array.
proc roots_quadratic_seq(): (string, int, float) =
    var sum = 0.0
    let steps = 1e6.int
    var v = @[-1.0, -1.0, 1.0]
    for i in 0 .. steps:
        sum += quadratic(v)[0]
    return ("roots_quadratic", steps, sum)
]#

proc circle_intersection(): (string, int, float) =
    var sum = 0.0
    let steps = 1e6.int
    var c = Circle().initCircle(pos=[0.0, 0.0], rad=0.5)
    var s = Segment().initSegment(p0=[0.0,0.0], p1=[1.0,1.0])
    for i in 0 .. steps:
        sum += c.intersection(s)[1]
    return ("circle_intersection", steps, sum)

benchmark(array_creation)
benchmark(array_modification)
benchmark(array_addition)
benchmark(seq_creation)
benchmark(seq_modification)
benchmark(segment_creation)
benchmark(roots_quadratic)
benchmark(circle_intersection)
