import ../roots

import std/math
import std/unittest

const
  eps: float = 1.0e-10

proc `=~` *(x, y: float): bool =
  result = abs(x - y) < eps

suite "roots tests":
    test "constant":
        let poly: array[3, float] = [1.0, 0.0, 0.0]
        let roots = quadratic(poly)
        check(isnan(roots[0]))
        check(isnan(roots[1]))

    test "line":
        let poly: array[3, float] = [1.0, -2.0, 0.0]
        let roots = quadratic(poly)
        check(roots[0] =~ 0.5)
        check(isnan(roots[1]))

    test "two real roots":
        let poly: array[3, float] = [-1.0, -1.0, 1.0]
        let roots: array[2, float] = quadratic(poly)
        let golden_0: float = (1.0 - sqrt(5.0)) / 2.0
        let golden_1: float = (1.0 + sqrt(5.0)) / 2.0
        check(roots[0] =~ golden_0)
        check(roots[1] =~ golden_1)

    test "two imag roots":
        let poly: array[3, float] = [1.0, 1.0, 1.0]
        let roots: array[2, float] = quadratic(poly)
        check(isnan(roots[0]))
        check(isnan(roots[1]))

    test "repeated root":
        let poly: array[3, float] = [1.0, -2.0, 1.0]
        let roots: array[2, float] = quadratic(poly)
        check(roots[0] =~ 1.0)
        check(roots[1] =~ 1.0)

    test "brent minimize polynomial":
        let poly: array[3, float] = [1.0, -1.0, 1.0]
        let function: proc(t: float): float = proc(t: float): float = 
            return polyeval(poly, t)

        let root = brent(f=function, bracket=[-2.0, 2.0], tol=1e-14, mintol=1e-14)
        check(root =~ 0.5)

    test "brent minimize sin":
        let function: proc(t: float): float = proc(t: float): float = 
            return sin(t)

        let root = brent(f=function, bracket=[-2.0, 2.0], tol=1e-16, mintol=1e-16)
        check(root =~ -PI/2)
        
