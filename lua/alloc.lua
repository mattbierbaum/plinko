local ffi_loaded, ffi = pcall(require, 'ffi')

local function convert_size(size)
    if type(size) ~= 'number' then
        return size
    end

    local prod = 1
    for i = 1, #size do
        prod = prod * size[i]
    end
    return prod
end

if not ffi_loaded then
    function create_array(size, dtype)
        local S = convert_size(size)
        local out = {}
        for i = 0, S-1 do
            out[i] = 0
        end
        return out
    end
else
    ffi.cdef[[
        void *malloc(size_t size);
        size_t free(void*);
    ]]

    function create_array(size, dtype)
        local S = convert_size(size)
        local out = ffi.gc(
            ffi.cast(dtype..'*', ffi.C.malloc(ffi.sizeof(dtype)*S)),
            ffi.C.free
        )
        for i = 0, S-1 do
            out[i] = 0
        end
        return out
    end
end

return {create_array=create_array}
