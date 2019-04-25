--[[
-- https://github.com/ers35/luastatic
--]]
local util = {}

function util.crequire(module)
    module_success, module = xpcall(
        function() return require(module) end,
        function(x) end
        --function(x) print('Could not load: ' .. module .. ', skipping...') end
    )
    return module_success and module or nil
end

local json = require('lib.dkjson')

function util.class(base, init)
	local c = {}
   	if not init and type(base) == 'function' then
    	init = base
      	base = nil
   	elseif type(base) == 'table' then
      	for i,v in pairs(base) do
         	c[i] = v
      	end
      	c._base = base
   	end
   	c.__index = c

   	local mt = {}
   	mt.__call = function(class_tbl, ...)
   		local obj = {}
   		setmetatable(obj,c)
		if c.init then
			c.init(obj, ...)
   		else 
   		   	if base and base.init then
   		   		base.init(obj, ...)
   		   	end
   		end
   		return obj
   	end

   	c.init = init
   	c.is_a = function(self, klass)
   	   	local m = getmetatable(self)
   	   	while m do 
   	      	if m == klass then return true end
   	      	m = m._base
   	   	end
   	   	return false
   	end

   	setmetatable(c, mt)
   	return c
end

function util.table_concat(t1,t2)
    for i=1, #t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

local function elapsed(f)
    local t0 = os.clock()
    local val1, val2 = f()
    local t1 = os.clock()
    return (t1 - t0), val1, val2
end

function util.timeit(f)
    local t, k, s = 1/0, 0, os.clock()
    while true do
        k = k + 1
        local tx, val1, val2 = elapsed(f)
        t = math.min(t, tx)
        if k > 5 and (os.clock() - s) >= 2 then break end
    end
    print(t)
end

function util.tprint(t)
    if json then
        print(json.encode(t, {indent=true}))
    else
        print(t)
    end
end

return util
