import roots

import std/math
import std/unittest

const
  eps = 1.0e-12

proc `=~` *(x, y: float): bool =
  result = abs(x - y) < eps

suite "quadratic tests":
    test "constant":
        let poly: seq[float] = @[1.0, 0.0, 0.0]
        let roots = quadratic(poly)
        check(isnan(roots[0]))
        check(isnan(roots[1]))

    test "line":
        let poly: seq[float] = @[1.0, -2.0, 0.0]
        let roots = quadratic(poly)
        check(roots[0] =~ 0.5)
        check(isnan(roots[1]))

    test "two real roots":
        let poly: seq[float] = @[-1.0, -1.0, 1.0]
        let roots: seq[float] = quadratic(poly)
        let golden_0: float = (1.0 - sqrt(5.0)) / 2.0
        let golden_1: float = (1.0 + sqrt(5.0)) / 2.0
        check(roots[0] =~ golden_0)
        check(roots[1] =~ golden_1)

    test "two imag roots":
        let poly: seq[float] = @[1.0, 1.0, 1.0]
        let roots: seq[float] = quadratic(poly)
        check(isnan(roots[0]))
        check(isnan(roots[1]))

    test "repeated root":
        let poly: seq[float] = @[1.0, -2.0, 1.0]
        let roots: seq[float] = quadratic(poly)
        check(roots[0] =~ 1.0)
        check(roots[1] =~ 1.0)