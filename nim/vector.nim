import std/math

type
    Vector = ref object of RootObj
        x, y: float64

proc `[]`* (v: Vector, i: int): float =
  case i
  of 0: result = v.x
  of 1: result = v.y
  else: assert(false)

proc `+`*(self: Vector, other: Vector): Vector =
    return Vector(x: self.x + other.x, y: self.y + other.y)

proc `+`*(self: Vector, other: float64): Vector =
    return Vector(x: self.x + other, y: self.y + other)

proc `+`*(other: float64, self: Vector): Vector =
    return Vector(x: self.x + other, y: self.y + other)

proc `-`*(self: Vector, other: Vector): Vector =
    return Vector(x: self.x - other.x, y: self.y - other.y)

proc `-`*(self: Vector, other: float64): Vector =
    return Vector(x: self.x - other, y: self.y - other)

proc `-`*(other: float64, self: Vector): Vector =
    return Vector(x: self.x - other, y: self.y - other)

proc `*`*(self: Vector, other: Vector): Vector =
    return Vector(x: self.x * other.x, y: self.y * other.y)

proc `*`*(self: Vector, other: float64): Vector =
    return Vector(x: self.x * other, y: self.y * other)

proc `*`*(other: float64, self: Vector): Vector =
    return Vector(x: self.x * other, y: self.y * other)

proc `/`*(self: Vector, other: Vector): Vector =
    return Vector(x: self.x / other.x, y: self.y / other.y)

proc `/`*(self: Vector, other: float64): Vector =
    return Vector(x: self.x / other, y: self.y / other)

proc `/`*(other: float64, self: Vector): Vector =
    return Vector(x: self.x / other, y: self.y / other)

proc `dot`*(self: Vector, other: Vector): float64 =
    return self.x * other.x + self.y * other.y

proc length*(self: Vector): float64 =
    return math.sqrt(self.dot(self))

proc lengthsq*(self: Vector): float64 =
    return self.dot(self)

proc rot90*(self: Vector): Vector = 
    return Vector(x: -self.y, y: self.x)

proc cross*(self: Vector, other: Vector): float64 =
    return self.x * other.y - self.y * other.x

proc norm*(self: Vector): Vector =
    var len = self.length
    return Vector(x: self.x / len, y: self.y / len)

proc reflect*(self: Vector, normal: Vector): Vector =
    let ddot = self.dot(normal)
    return self - (2.0 * ddot * normal)

proc lerp*(v0: Vector, v1: Vector, t: float64): Vector =
    return (1 - t)*v0 + t*v1

proc ilerp*(v0: Vector, v1: Vector, t: Vector): float64 =
    let d = v0 - v1
    if abs(d.x) < abs(d.y):
        return (t.y - v0.y) / d.y
    else:
        return (t.x - v0.x) / d.x

proc rotate*(v: Vector, theta: float64): Vector = 
    let c = cos(theta)
    let s = sin(theta)
    return Vector(x: v.x*c - v.y*s, y: v.x*s + v.y*c)
