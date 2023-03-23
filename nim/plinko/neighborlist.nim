import objects
import vector

import std/math
import std/strformat
import std/tables
import std/lenientops

proc swap*(a: float, b: float): (float, float) = return (b, a)
proc swap*(a: int, b: int): (int, int) = return (b, a)

# ==============================================
type
    RetObjects* = ref object of RootObj
        objs*: seq[Object]
        count*: int

# ==============================================
type
    Neighborlist* = ref object of RootObj
        robjects*: RetObjects

proc initNeighborlist*(self: Neighborlist): Neighborlist =
    self.robjects = RetObjects()
    self.robjects.objs = newSeq[Object]()
    self.robjects.count = 0
    return self

method append*(self: Neighborlist, obj: Object): void {.base.} = 
    self.robjects.objs.add(obj)
    self.robjects.count += 1

method calculate*(self: Neighborlist): void {.base.} = return
method near*(self: Neighborlist, seg: Seg): RetObjects {.base.} = self.robjects
method contains*(self: Neighborlist, seg: Seg): bool {.base.} = true
method show*(self: Neighborlist): void {.base.} = return
method `$`*(self: Neighborlist): string {.base.} = ""

# ==============================================
type
    CellNeighborlist* = ref object of Neighborlist
        buffer*: float
        cell*: Vec
        ncells*: array[2, int]
        cells*: seq[seq[Object]]
        seen*: Table[int, Table[int, bool]]
        objects*: seq[Object]
        box*: Box
        near_seen*: seq[bool]
        output*: RetObjects

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

    let N = (self.ncells[0]+1)*(self.ncells[1]+1)
    self.objects = @[]
    self.seen = initTable[int, Table[int, bool]]()
    self.cells = newSeq[seq[Object]](N+1)
    for i in 0 .. N:
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
    if not self.seen.hasKey(ind):
        return
    if not self.seen[ind].hasKey(l):
        self.seen[ind][l] = true
        self.cells[ind].add(obj)

method calculate*(self: CellNeighborlist): void =
    for l, obj in self.objects:
        let ind = self.point_to_index(obj.center())
        self.add_to_cell(ind[0], ind[1], l, obj)

    for i in 0 .. self.ncells[0]-1:
        for j in 0 .. self.ncells[1]-1:
            let box = self.cell_box(i, j)

            for k in 0 .. box.segments.len-1:
                let seg = box.segments[k]
                for l, obj in self.objects:
                    let s = Seg(p0:seg.p0, p1:seg.p1)
                    let t = obj.intersection(s)[1]
                    if t >= 0 and t <= 1:
                        self.add_to_cell(i, j, l, obj)

    var max_index = 0
    for obj in self.objects:
        if obj.index > max_index:
            max_index = obj.index
    self.near_seen = newSeq[bool](max_index+1)

    self.output = RetObjects()
    self.output.objs = newSeq[Object](max_index+1)
    self.output.count = 0

proc addcell*(self: CellNeighborlist, i: int, j: int, output: RetObjects): void =
    assert(i >= 0 or i <= self.ncells[0] or j >= 0 or j <= self.ncells[1])
    let ind = self.cell_ind(i, j)
    if ind < 0 or ind > self.cells.len:
        return
    for obj in self.cells[ind]:
        if not self.near_seen[obj.index]:
            self.near_seen[obj.index] = true
            output.objs[output.count] = obj
            output.count += 1

method contains*(self: CellNeighborlist, seg: Seg): bool =
    return (seg.p0 >= self.box.ll and seg.p0 <= self.box.uu and
            seg.p1 >= self.box.ll and seg.p1 <= self.box.uu)

proc clear_cache*(self: CellNeighborlist): void =
    for i in 0 .. self.output.count-1:
        let obj = self.output.objs[i]
        self.near_seen[obj.index] = false

method near*(self: CellNeighborlist, seg: Seg): RetObjects =
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
    self.output.count = 0

    # short-circuit things that don't leave a single cell
    if (ix0 == ix1 and iy0 == iy1):
        self.addcell(ix0, iy0, self.output)
        self.clear_cache()
        return self.output

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

    for x in  ix0 .. ix1:
        let iy0 = floor(dydx * (x - x0) + y0).int
        let iy1 = floor(dydx * (x + 1 - x0) + y0).int

        if steep:
            if iy0 == iy1:
                self.addcell(iy0, x, self.output)
            else:
                self.addcell(iy0, x, self.output)
                self.addcell(iy1, x, self.output)
        else:
            if iy0 == iy1:
                self.addcell(x, iy0, self.output)
            else:
                self.addcell(x, iy0, self.output)
                self.addcell(x, iy1, self.output)

    self.clear_cache()
    return self.output

method `$`*(self: CellNeighborlist): string =
    var o = "CellNeighborlist: \n"
    o &= fmt"  {self.box}" & "\n"
    o &= fmt"  ncells = {self.ncells}" & "\n"

    o &= "|"
    for i in 0 .. self.ncells[0]:
        o &= "-"
    o &= "|\n" 

    for j in countdown(self.ncells[1], 0):
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