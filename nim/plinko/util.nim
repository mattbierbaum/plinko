import std/strutils

proc indent*(s: string, indent: string = "  "): string =
    var lines = s.split("\n")
    var output = ""
    for line in lines:
        if line.len > 0:
            output &= indent & line.strip(chars={'\n'}) & "\n"
    return output

# =================================================================
type
    Pmt*[T] = ref object of RootObj
        offset*: int
        count*: int 
        active*: int
        has_value*: seq[bool]
        value*: seq[T]

proc initPmt*[T](self: Pmt[T], offset: int, count: int): Pmt[T] =
    self.offset = offset
    self.count = count
    self.active = 0
    self.has_value = newSeq[bool](self.count)
    self.value = newSeq[T](self.count)
    return self

proc contains*[T](self: Pmt[T], index: int): bool =
    return index >= self.offset and index <= self.offset + self.count

proc seen*[T](self: Pmt[T], index: int): bool =
    return self.has_value[index - self.offset]

proc get*[T](self: Pmt[T], index: int): T =
    return self.value[index - self.offset]

proc set*[T](self: Pmt[T], index: int, value: T): void =
    self.value[index - self.offset] = value
    if not self.seen(index):
        self.has_value[index - self.offset] = true
        self.active += 1

proc remove*[T](self: Pmt[T], index: int): void =
    if self.seen(index):
        self.has_value[index - self.offset] = false
        self.active -= 1

iterator iter*[T](self: Pmt[T]): (int, T) =
    for i in 0 .. self.count-1:
        if self.has_value[i]:
            yield (i+self.offset, self.value[i])

proc join*[T](t0: Pmt[T], t1: Pmt[T]): Pmt[T] =
    var o = Pmt[T]().initPmt(
        offset=min(t0.offset, t1.offset), 
        count=max(t0.offset+t0.count, t1.offset+t1.count)-min(t0.offset, t1.offset))
    for ind, val in t0.iter():
        o.set(ind, val)
    for ind, val in t1.iter():
        o.set(ind, val)
    return o

