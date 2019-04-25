local plinko = require('plinko')

_G['P'] = plinko
_G['plinko'] = plinko

function dofile(filename)
    local f = assert(loadfile(filename))
    return f()
end

if #arg < 1 then
    print("plinko <script.lua> <args>")
else
    dofile(table.remove(arg, 1))
end
