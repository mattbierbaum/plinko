local plinko = require('plinko')

_G['P'] = plinko
_G['plinko'] = plinko

function dofile(filename)
    local f = assert(loadfile(filename))
    return f()
end

dofile(table.remove(arg, 1))
