# import std/strformat

type 
    Array2D*[T] = object
        shape*: array[2, int]
        size*: int
        data*: seq[T]
        dtype*: typedesc T

proc initArray2D*(self: Array2D, shape: array[2, int]): Array2D =
    self.shape = shape
    self.size = shape[0] * shape[1]
    self.data = newSeq[self.dtype]()

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

proc minmax_cut*(arr: seq[float], cutoff: float=1e-15): (float, float) =
    var (min, max) = (high(float), low(float))
    for val in arr:
        if min > val and val > cutoff:
            min = val
        if max < val:
            max = val
    return (min, max)

#[
proc save_csv*(arr: seq[float], filename: string, mode: string = "W"): void =
    # assert(#self.shape < 3, 'array is > 2D, cannot save CSV')

    var file: File
    if mode == "a":
        file = open(filename, fmAppend)
        file.setFilePos(0, fspEnd)
    else:
        file = open(filename, fmWrite)

    if #self.shape == 1 then
        for i = 0, self.shape[1]-1 do
            file.write(fmt"{self.arr[i]}\n")
        end
    end

    if #self.shape == 2 then
        for j = 0, self.shape[2]-1 do
            for i = 0, self.shape[1]-1 do
                file.write(string.format(fmt..' ', self.arr[i+j*self.shape[1]]))
            end
            file.write("\n")
        end
    end

    file:close()
end

function ArrayBase:save_bin(file, mode)
    assert(#self.shape < 3, 'array is > 2D, cannot save')

    if mode == 'a' then
        file = io.open(file, 'ab')
        file:seek('end')
    else
        file = io.open(file, 'wb')
    end

    local fmt = '<'..dtypes_struct[self.dtype]

    if #self.shape == 1 then
        for i = 0, self.shape[1]-1 do
            file:write(struct.pack(fmt, self.arr[i]))
        end
    end

    if #self.shape == 2 then
        for j = 0, self.shape[2]-1 do
            for i = 0, self.shape[1]-1 do
                file:write(struct.pack(fmt, self.arr[i+j*self.shape[1]]))
            end
        end
    end

    file:close()
end

proc save_pgm2*(arr: seq[float], filename: string, shape: array[2, int]): void =
    let file = open(filename, fmWrite)
    file.write(fmt"P2 {shape[1]} {shape[0]} 255\n")
    file.close()

    self:save_csv(filename, 'a')

proc save_pgm5*(arr: seq[float], filename: string, shape: array[2, int]): void =
    let file = open(filename, fmWrite)
    file.write(fmt"P5 {shape[0]} {shape[1]} 255\n")
    file.close()

    self.save_bin(filename, 'a')
]#