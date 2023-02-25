import std/os
import std/streams
import std/strformat
import std/strutils

type
    Array2D*[T] = ref object of RootObj
        data*: seq[T]
        shape*: array[2, int]
        size*: int

proc initArray2D*[T](self: Array2D[T], shape: array[2, int]): Array2D[T] =
    self.shape = shape
    self.size = shape[0] * shape[1]
    self.data = newSeq[T](self.size)
    return self

proc clamp_index*(self: Array2D, index: int): int =
    return max(min(index, self.size-1), 0)

proc clamp_index*(arr: seq[float], index: int): int =
    return max(min(index, arr.len-1), 0)

proc sum*(arr: seq[float]): float =
    var s: float = 0.0
    for v in arr:
        s = s + v
    return s

proc sum*(arr: seq[int]): int =
    var s: int = 0
    for v in arr:
        s = s + v
    return s

proc minmax*(arr: seq[float]): (float, float) =
    var (min, max) = (1e100, -1e100)
    for val in arr:
        if min > val:
            min = val
        if max < val:
            max = val
    return (min, max)

proc minmax_cut*(arr: seq[float], cutoff: float = 1e-15): (float, float) =
    var (min, max) = (high(float), low(float))
    for val in arr:
        if min > val and val > cutoff:
            min = val
        if max < val:
            max = val
    return (min, max)

proc save_csv*[T](self: Array2D[T], filename: string,
        mode: string = "w"): void =
    var file: File
    if mode == "a":
        file = open(filename, fmAppend)
        file.setFilePos(0, fspEnd)
    else:
        file = open(filename, fmWrite)

    for j in 0 .. self.shape[1]-1:
        for i in 0 .. self.shape[0]-1:
            file.write(fmt"{self.data[i+j*self.shape[0]]} ")
        file.write("\n")
    file.close()

proc save_bin*[T](self: Array2D[T], filename: string, mode: string = "w"): void =
    let filesize:int = getFileSize(filename).int
    var file: FileStream
    if mode == "a":
        file = newFileStream(filename, fmAppend)
        file.setPosition(filesize)
    else:
        file = newFileStream(filename, fmWrite)

    for j in 0 .. self.shape[1]-1:
        for i in 0 .. self.shape[0]-1:
            file.write(self.data[i+j*self.shape[1]])
    file.close()

proc save_pgm2*(self: Array2D[uint8], filename: string): void =
    let file = open(filename, fmWrite)
    file.write(fmt"P2 {self.shape[1]} {self.shape[0]} 255" & "\n")
    file.close()

    self.save_csv(filename, "a")

proc save_pgm5*(self: Array2D[uint8], filename: string): void =
    let file = open(filename, fmWrite)
    file.write(fmt"P5 {self.shape[0]} {self.shape[1]} 255" & "\n")
    file.close()

    self.save_bin(filename, "a")
