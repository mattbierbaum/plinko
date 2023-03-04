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