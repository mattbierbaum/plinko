import objects
import vector

import std/math
import std/tables
import std/lenientops

proc swap*(a: float, b: float): (float, float) = return (b, a)
proc swap*(a: int, b: int): (int, int) = return (b, a)


# ==============================================
type
    NaiveNeighborlist = ref object of RootObj
        objects*: seq[Object]

proc append*(self: NaiveNeighborlist, obj: Object): void {.discardable.} = self.objects.add(obj)
proc calculate*(self: NaiveNeighborlist): void {.discardable.} = return
proc near*(self: NaiveNeighborlist, seg: Segment): seq[Object] = self.objects

# ==============================================
type
    CellNeighborlist = ref object of RootObj
        buffer*: float
        cell*: Vec
        ncells*: array[2, int]
        objects*: seq[Object]
        cells*: Table[int, seq[Object]]
        seen*: Table[int, Table[int, bool]]
        box*: Box

proc initCellNeighborlist*(self: CellNeighborlist, box: Box, ncells: array[2, int], buffer: float = -1): CellNeighborlist =
    let sidelength: float = max(box.uu[0] - box.ll[0], box.uu[1] - box.ll[1])
    self.buffer = if buffer > 0: buffer else: 2.0/ncells[0].float
    self.buffer = self.buffer * sidelength

    self.ncells = ncells
    self.box = Box().initBox(box.ll - self.buffer, box.uu - self.buffer)
    self.cell = [
        (self.box.uu[1] - self.box.ll[1]) / self.ncells[0].float,
        (self.box.uu[2] - self.box.ll[2]) / self.ncells[1].float
    ]

    self.objects = @[]
    self.seen = initTable[int, Table[int, bool]]()
    self.cells = initTable[int, seq[Object]]()
    for i in 0 .. (self.ncells[0]+1)*(self.ncells[1]+1):
        self.seen[i] = initTable[int, bool]()
        self.cells[i] = @[]

proc cell_ind*(self: CellNeighborlist, i: int, j: int): int =
    return i + j*self.ncells[0]

proc cell_box*(self: CellNeighborlist, i: int, j: int): Box =
    let fractx: float = i.float / self.ncells[0].float
    let fracty: float = j.float / self.ncells[1].float

    let x0 = (1 - fractx) * self.box.ll[0]  + fractx * self.box.uu[0]
    let y0 = (1 - fracty) * self.box.ll[1]  + fracty * self.box.uu[1]
    let x1 = x0 + self.cell[0]
    let y1 = y0 + self.cell[1]
    return Box().initBox([x0, y0], [x1, y1])

proc point_to_index*(self: CellNeighborlist, p: Vec): array[2, int] =
    return [
        floor((p[0] - self.box.ll[0]) / self.cell[0]).int,
        floor((p[1] - self.box.ll[1]) / self.cell[1]).int
    ]

proc append*(self: CellNeighborlist, obj: Object): void {.discardable.} = self.objects.add(obj)

proc add_to_cell*(self: CellNeighborlist, ci: int, cj: int, l: int, obj: Object): void =
    let ind = self.cell_ind(ci, cj)
    var s = self.seen[ind]
    var t = self.cells[ind]

    if not s.hasKey(l):
        s[l] = true
        t.add(obj)

proc calculate*(self: CellNeighborlist): void {.discardable.} = 
    for l, obj in self.objects:
        let obj = self.objects[l]
        let ind = self.point_to_index(obj.center())
        self.add_to_cell(ind[0], ind[1], l, obj)

    for i in 0 .. self.ncells[0]-1:
        for j in 0 .. self.ncells[1]-1:
            let box = self.cell_box(i, j)

            for k in 0 .. box.segments.len-1:
                let seg = box.segments[k]
                for l, obj in self.objects:
                    let obj = self.objects[l]
                    let t = obj.intersection(seg)[1]
                    if t > 0:
                        self.add_to_cell(i, j, l, obj)

proc addcell*(self: CellNeighborlist, i: int, j: int, objs: var seq[Object]): void {.discardable.} =
    assert(i >= 0 or i <= self.ncells[0] or j >= 0 or j <= self.ncells[1])
    let ind = self.cell_ind(i, j)
    let cell = self.cells[ind]
    for c in 0 .. cell.len:
        objs.add(cell[c])

proc near*(self: CellNeighborlist, seg: Segment, verbose: bool = false): seq[Object] =
    let box = self.box
    let cell = self.cell
    var x0 = (seg.p0[0] - box.ll[0]) / cell[0]
    var y0 = (seg.p0[1] - box.ll[1]) / cell[1]
    var x1 = (seg.p1[0] - box.ll[0]) / cell[0]
    var y1 = (seg.p1[1] - box.ll[1]) / cell[1]

    var ix0 = floor(x0).int
    var ix1 = floor(x1).int
    var iy0 = floor(y0).int
    var iy1 = floor(y1).int

    var steep = abs(y1 - y0) > abs(x1 - x0)

    # short-circuit things that don't leave a single cell
    if (ix0 == ix1 and iy0 == iy1):
        return self.cells[self.cell_ind(ix0, iy0)]

    if steep:
        (x0, y0) = swap(x0, y0)
        (x1, y1) = swap(x1, y1)
    if x0 > x1:
        (x0, x1) = swap(x0, x1)
        (y0, y1) = swap(y0, y1)

    var dx = x1 - x0
    var dy = y1 - y0
    var dydx = dy / dx

    ix0 = floor(x0).int
    ix1 = ceil(x1).int

    var objs: seq[Object] = @[]
    for x in  ix0 .. ix1:
        let iy0 = floor(dydx * (x - x0) + y0).int
        let iy1 = floor(dydx * (x + 1 - x0) + y0).int

        if steep:
            if iy0 == iy1:
                self.addcell(iy0, x, objs)
            else:
                self.addcell(iy0, x, objs)
                self.addcell(iy1, x, objs)
        else:
            if iy0 == iy1:
                self.addcell(x, iy0, objs)
            else:
                self.addcell(x, iy0, objs)
                self.addcell(x, iy1, objs)
    return objs

#[
proc show*(self: CellNeighborlist): void {.discardable.} =
    echo '|'
    for i = 1, self.ncells[1] do
        io.write('-')
    end
    io.write('|')
    io.write('\n')

    for j = self.ncells[2], 0, -1 do
        io.write('|')
        for i = 0, self.ncells[1] do
            if #self.cells[self:cell_ind(i, j)] > 0 then
                io.write('*')
            else
                io.write(' ')
            end

        end
        io.write('|')
        io.write('\n')
    end

    io.write('|')
    for i = 1, self.ncells[1] do
        io.write('-')
    end
    io.write('|')
    io.write('\n')
end
]#

#[
#  psuedo code for neighborlisting arbitrary objects:
#    - each object has a parametric representation (x(t), y(y))
#    - step along the curve and find edges that intersect, adding the object to the nodes
#       * initial condition t0 = (x0, y0)
#       * find segments surrounding and find earliest intersection (store t_cross_obj, t_cross_seg) (add object to node)
#       * try all 6 neighboring edges and find next intersection (later than t_cross_obj)
#       * continue until no more crossings
]#