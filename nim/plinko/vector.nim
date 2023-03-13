import std/math
import std/strformat

type Vec* = array[2, float]

proc `+`*(v: Vec, u: Vec): Vec {.inline.} = [v[0] + u[0], v[1] + u[1]]
proc `+`*(v: Vec, u: float): Vec {.inline.} = [v[0] + u, v[1] + u]
proc `+`*(u: float, v: Vec): Vec {.inline.} = v + u

proc `-`*(v: Vec): Vec {.inline.} = [-v[0], -v[1]]
proc `-`*(v: Vec, u: Vec): Vec {.inline.} = [v[0] - u[0], v[1] - u[1]]
proc `-`*(v: Vec, s: float): Vec {.inline.} = [v[0] - s, v[1] - s]
proc `-`*(s: float, v: Vec): Vec {.inline.} = [s - v[0], s - v[1]]

proc `*`*(v: Vec, u: Vec): Vec {.inline.} = [v[0] * u[0], v[1] * u[1]]
proc `*`*(v: Vec, s: float): Vec {.inline.} = [v[0] * s, v[1] * s]
proc `*`*(s: float, v: Vec): Vec {.inline.} = v * s

proc `/`*(v: Vec, u: Vec): Vec {.inline.} = [v[0] / u[0], v[1] / u[1]]
proc `/`*(v: Vec, s: float): Vec {.inline.} = v * (1/s)

proc `>`*(v: Vec, u: Vec): bool {.inline.} = v[0] > u[0] and v[1] > u[1]
proc `<`*(v: Vec, u: Vec): bool {.inline.} = v[0] < u[0] and v[1] < u[1]
proc `>=`*(v: Vec, u: Vec): bool {.inline.} = v[0] >= u[0] and v[1] >= u[1]
proc `<=`*(v: Vec, u: Vec): bool {.inline.} = v[0] <= u[0] and v[1] <= u[1]

proc `dot`*(v: Vec, u: Vec): float {.inline.} = v[0] * u[0] + v[1] * u[1]
proc length*(v: Vec): float {.inline.} = math.sqrt(v.dot(v))
proc lengthsq*(v: Vec): float {.inline.} = v.dot(v)
proc cross*(v: Vec, u: Vec): float {.inline.} = v[0] * u[1] - v[1] * u[0]
proc norm*(v: Vec): Vec {.inline.} = v / v.length
proc reflect*(v: Vec, normal: Vec): Vec {.inline.} = v - (2.0 * v.dot(normal) * normal)
proc lerp*(v0: Vec, v1: Vec, t: float): Vec {.inline.} = (1 - t)*v0 + t*v1
proc vlerp*(v0: Vec, v1: Vec, t: Vec): Vec {.inline.} = (1 - t)*v0 + t*v1

proc ilerp*(v0: Vec, v1: Vec, t: Vec): float {.inline.} =
    let d = v0 - v1
    if abs(d[0]) < abs(d[1]):
        return (t[1] - v0[1]) / d[1]
    else:
        return (t[0] - v0[0]) / d[0]

proc rot90*(v: Vec): Vec {.inline.} = [-v[1], v[0]]

proc rotate*(v: Vec, theta: float): Vec {.inline.} = 
    let c = cos(theta)
    let s = sin(theta)
    return [v[0]*c - v[1]*s, v[0]*s + v[1]*c]

proc `$`*(v: Vec): string = fmt"[{v[0]}, {v[1]}]"

proc min*(v0: Vec, v1: Vec): Vec {.inline.} =
    return [min(v0[0], v1[0]), min(v0[1], v1[1])]

proc max*(v0: Vec, v1: Vec): Vec {.inline.} =
    return [max(v0[0], v1[0]), max(v0[1], v1[1])]