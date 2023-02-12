import objects
import vector

import std/math
import std/unittest

const
  eps = 1.0e-10

proc `=~` *(x, y: float): bool =
    return abs(x - y) < eps

proc `=~` *(x, y: Vec): bool =
    let d = y - x
    return abs(d[0]) < eps and abs(d[1]) < eps

suite "objects tests":
    test "segments":
        let s0 = Segment().initSegment([0.0, 0.0], [1.0, 0.0])
        let s1 = Segment().initSegment([0.5, 0.5], [0.5, -0.25])

        check(s0.length() =~ 1.0)
        check(s1.length() =~ 0.75)

        check(s0.center() =~ [0.5, 0.0])
        check(s0.normal(s1) =~ [0.0, -1.0])

        check(s1.intersection(s0) == 0.5)
        check(s0.intersection(s1) == 2.0/3.0)

    test "circles":
        let c0 = Circle().initCircle(pos=[0.0, 0.0], rad=1.0)
        let s0 = Segment().initSegment([0.0, 0.0], [1.0, 1.0])
        let s1 = Segment().initSegment([0.0, 0.0], [0.0, 2.0])

        check(c0.center() =~ [0.0, 0.0])
        check(c0.intersection(s0) =~ sqrt(2.0)/2.0)
        check(c0.intersection(s1) =~ 0.5)
        check(c0.crosses(s0))

    test "rectangles":
        let r = Rectangle().initRectangle([0.0, 0.0], [1.0, 1.0])
        let s0 = Segment().initSegment([0.5, 0.5], [1.5, 0.5])
        let s1 = Segment().initSegment([0.5, 0.5], [-1.5, 0.5])

        check(r.intersection(s0) =~ 0.5)
        check(r.intersection(s1) =~ 0.25)
        check(r.center() =~ [0.5, 0.5])