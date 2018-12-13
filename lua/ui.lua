local util = require('util')

Area = util.class()
function Area:init(loc)
    if loc.x and loc.y then
        self.x = loc.x
        self.y = loc.y
        
        if loc.size then
            self.w = loc.size
            self.h = loc.size
        elseif loc.w and loc.h then
            self.w = loc.w
            self.h = loc.h
        end
    end
end

Window = util.class()
function Window:init(args)
    self.child = args.child or {}
    self.parent = args.parent or nil
    self.bbox = args.box
end

function Window:child_add(child)
    self.child[#self.child + 1] = child
end

