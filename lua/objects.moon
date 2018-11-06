class Vec2D
    new: (x, y) =>
        @x = x
        @y = y

    length: =>
        return math.sqrt(@x*@x + @y*@y)

class Object
    new: =>
        @items = {}

    update: (position) => false

class Circle
    new: (@pos, @rad) =>
        @sign = 1

    update: (pos) =>
        dr = pos - @pos
        sign = dr.length < @rad

print Vec2D(1, 1).length()
