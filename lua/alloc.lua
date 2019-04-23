local util = require('util')
local ffi = util.crequire('ffi')
local js = util.crequire('js')
local struct = util.crequire('struct')

local struct_dtypes = {
    double = 'd',
    float = 'f',
    ubyte = 'B',
    byte = 'b',
    int = 'i',
    uint = 'I',
    long = 'l',
    ulong = 'L'
}

local function convert_size(size)
    if type(size) == 'number' then
        return size
    end

    local prod = 1
    for i = 1, #size do
        prod = prod * size[i]
    end
    return prod
end

--================================================
ArrayBase = util.class()

function ArrayBase:init(size, dtype)
    self.dtype = dtype
    self.size = convert_size(size)
    self.shape = size
end

function ArrayBase:zero()
    for i = 0, self.size-1 do
        self.arr[i] = 0
    end
end

function ArrayBase:save_csv(filename)
    if #self.shape > 2 then
        print("Array is > 2D, cannot save CSV")
        return
    end
    file = io.open(filename, 'w')

    if #self.shape == 1 then
        file:write(table.concat(self.arr, '\n'))
    end

    if #self.shape == 2 then
        for i = 0, self.size[1]-1 do
            file:write(table.concat(self.arr[i], ', '))
            file:write('\n')
        end
    end

    file:close()
end

function ArrayBase:save_bin(filename)

end

--================================================
ArrayLua = util.class(ArrayBase)

function ArrayLua:init(size, dtype)
    ArrayBase.init(self, size, dtype)
    self.arr = {}
    self:zero()
end

--================================================
ArrayJS = util.class(ArrayBase)

function ArrayJS:init(size, dtype)
    ArrayBase.init(self, size, dtype)

    local dtypes = {
        float = js.global.Float32Array,
        double = js.global.Float64Array,
        int = js.global.Int32Array,
        long = js.global.Int64Array,
    }

    self.arr = dtypes[dtype](self.size)
    self:zero()
end

--================================================
ArrayC = util.class(ArrayBase)

function ArrayC:init(size, dtype)
    ArrayBase.init(self, size, dtype)
    self.arr = ffi.gc(
        ffi.cast(dtype..'*', ffi.C.malloc(ffi.sizeof(dtype)*self.size)),
        ffi.C.free
    )
    self:zero()
end

function ArrayC:tofile(filename)
    file = ffi.C.fopen(filename, 'wb')
    ffi.C.fwrite(self.arr, ffi.sizeof(self.dtype), self.S, file)
    ffi.C.fclose(file)
end

function ArrayC:fromfile(filename)
    file = ffi.C.fopen(filename, 'rb')
    ffi.C.fread(self.arr, ffi.sizeof(self.dtype), self.S, file)
    ffi.C.fclose(file)
end

if js then
    Array = ArrayJS
else
    if not ffi then
        Array = ArrayLua
    else
        ffi.cdef[[
            typedef struct {
              char *fpos;
              void *base;
              unsigned short handle;
              short flags;
              short unget;
              unsigned long alloc;
              unsigned short buffincrement;
            } FILE;

            FILE *fopen(const char *filename, const char *mode);
            size_t fread(void *ptr, size_t size, size_t N, FILE *file);
            size_t fwrite(const void *ptr, size_t size, size_t N, FILE *file);
            int fclose(FILE *file);

            void *malloc(size_t size);
            size_t free(void*);
        ]]

        Array = ArrayC
    end
end

function create_array(size, dtype)
    return Array(size, dtype).arr
end

return {Array=Array, create_array=create_array}
