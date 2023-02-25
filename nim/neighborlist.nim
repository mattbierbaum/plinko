import objects
import vector

import std/math
import std/tables
import std/lenientops

proc swap*(a: float, b: float): (float, float) = return (b, a)
proc swap*(a: int, b: int): (int, int) = return (b, a)


# ==============================================
type
    Neighborlist* = ref object of RootObj
        objects*: seq[Object]

method append*(self: Neighborlist, obj: Object): void {.base.} = self.objects.add(obj)
method calculate*(self: Neighborlist): void {.base.} = return
method near*(self: Neighborlist, seg: Segment): seq[Object] {.base.} = self.objects
method show*(self: Neighborlist): void {.base.} = return
method `$`*(self: Neighborlist): string {.base.} = ""

# ==============================================
type
    CellNeighborlist* = ref object of Neighborlist
        buffer*: float
        cell*: Vec
        ncells*: array[2, int]
        cells*: Table[int, seq[Object]]
        seen*: Table[int, Table[int, bool]]
        box*: Box

proc initCellNeighborlist*(self: CellNeighborlist, box: Box, ncells: array[2, int], buffer: float = -1): CellNeighborlist =
    let sidelength: float = max(box.uu[0] - box.ll[0], box.uu[1] - box.ll[1])
    self.buffer = if buffer > 0: buffer else: 2.0/ncells[0].float
    self.buffer = self.buffer * sidelength

    self.ncells = ncells
    self.box = Box().initBox(box.ll - self.buffer, box.uu + self.buffer)
    self.cell = [
        (self.box.uu[0] - self.box.ll[0]) / self.ncells[0].float,
        (self.box.uu[1] - self.box.ll[1]) / self.ncells[1].float
    ]

    self.objects = @[]
    self.seen = initTable[int, Table[int, bool]]()
    self.cells = initTable[int, seq[Object]]()
    for i in 0 .. (self.ncells[0]+1)*(self.ncells[1]+1):
        self.seen[i] = initTable[int, bool]()
        self.cells[i] = @[]
    return self

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

method append*(self: CellNeighborlist, obj: Object): void = 
    self.objects.add(obj)

proc add_to_cell*(self: CellNeighborlist, ci: int, cj: int, l: int, obj: Object): void =
    let ind = self.cell_ind(ci, cj)
    if not self.seen[ind].hasKey(l):
        self.seen[ind][l] = true
        self.cells[ind].add(obj)

method calculate*(self: CellNeighborlist): void =
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
                    if t >= 0 and t <= 1:
                        self.add_to_cell(i, j, l, obj)

proc addcell*(self: CellNeighborlist, i: int, j: int, objs: var seq[Object]): void =
    assert(i >= 0 or i <= self.ncells[0] or j >= 0 or j <= self.ncells[1])
    let ind = self.cell_ind(i, j)
    for obj in self.cells[ind]:
        objs.add(obj)

method near*(self: CellNeighborlist, seg: Segment): seq[Object] =
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

method `$`*(self: CellNeighborlist): string =
    var o = ""
    o &= "|"
    for i in 0 .. self.ncells[0]:
        o &= "-"
    o &= "|\n" 

    for j in 0 .. self.ncells[1]:
        o &= "|"
        for i in 0 .. self.ncells[0]:
            if len(self.cells[self.cell_ind(i, j)]) > 0:
                o &= "*"
            else:
                o &= " "
        o &= "|"
        o &= "\n"

    o &= "|"
    for i in 0 .. self.ncells[0]:
        o &= "-"
    o &= "|"
    o &= "\n"
    return o

method show*(self: CellNeighborlist): void = 
    echo $self

#[
#  psuedo code for neighborlisting arbitrary objects:
#    - each object has a parametric representatstdoutn (x(t), y(y))
#    - step along the curve and find edges that intersect, adding the object to the nodes
#       * initial conditstdoutn t0 = (x0, y0)
#       * find segments surrounding and find earliest intersectstdoutn (store t_cross_obj, t_cross_seg) (add object to node)
#       * try all 6 neighboring edges and find next intersectstdoutn (later than t_cross_obj)
#       * continue until no more crossings
]#