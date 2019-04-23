local util = require('util')
local ffi = util.crequire('ffi')
local js = util.crequire('js')
local struct = util.crequire('struct')

local dtypes_struct = {
    float = 'f', double = 'd',
    ubyte = 'B', byte = 'b',
    uint = 'I',  int = 'i',
    ulong = 'L', long = 'l',
}

local dtypes_format = {
    float = 'f', double = 'f',
    ubyte = 'c', byte = 'c',
    uint = 'u',  int = 'i',
    ulong = 'L', long = 'l',
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
    if type(size) == 'number' then
        size = {size}
    end

    self.dtype = dtype
    self.size = convert_size(size)
    self.shape = size
end

function ArrayBase:zero()
    for i = 0, self.size-1 do
        self.arr[i] = 0
    end
end

function ArrayBase:save_csv(file)
    assert(#self.shape < 3, 'array is > 2D, cannot save CSV')
    if type(file) == 'string' then
        file = io.open(file, 'w')
    end
    fmt = '%'..dtypes_format[self.dtype]

    if #self.shape == 1 then
        for i = 0, self.shape[1]-1 do
            file:write(string.format(fmt..'\n', self.arr[i]))
        end
    end

    if #self.shape == 2 then
        for j = 0, self.shape[2]-1 do
            for i = 0, self.shape[1]-1 do
                file:write(string.format(fmt..' ', self.arr[i+j*self.shape[1]]))
            end
            file:write('\n')
        end
    end

    file:close()
end

function ArrayBase:save_bin(file)
    assert(#self.shape < 3, 'array is > 2D, cannot save')
    if type(file) == 'string' then
        file = io.open(file, 'wb')
    end
    fmt = '<'..dtypes_struct[self.dtype]

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

function ArrayBase:save_pgm2(filename)
    file = io.open(filename, 'w')
    file:write(string.format('P2 %i %i %i\n', self.shape[2], self.shape[1], 255))
    file:close()

    self:save_csv(io.open(filename, 'a'))
end

function ArrayBase:save_pgm5(filename)
    file = io.open(filename, 'w')
    file:write(string.format('P5 %i %i %i\n', self.shape[2], self.shape[1], 255))
    file:close()

    self:save_bin(io.open(filename, 'ab'))
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

function ArrayC:save_bin(filename)
    file = ffi.C.fopen(filename, 'wb')
    ffi.C.fwrite(self.arr, ffi.sizeof(self.dtype), self.size, file)
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
    return Array(size, dtype)
end

return {Array=Array, create_array=create_array}
