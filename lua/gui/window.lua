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

function Area:contains(pt)
    local x = pt[1]
    local y = pt[2]

    if x >= self.x and x <= self.x + self.w and
       y >= self.y and y <= self.y + self.h then
       return true
   end
   return false
end

--function Area:subarea(loc)

Window = util.class()
function Window:init(args)
    self.child = args.child or {}
    self.parent = args.parent or nil
    self.bbox = args.box
    self.dirty = true
end

function Window:child_add(child)
    self.child[#self.child + 1] = child
end

function Window:draw()
    -- draw is not the same thing as paint
    -- paint actual renders to a buffer, draw blits the buffer
    self:draw()
    for child in self.child do
        child:draw()
    end
end

function Window:paint()
    if self.dirty then
        self:paintborder()
    end
end

function Window:keypressed(key, isrepeat)
end

function Window:keyreleased(key)
end

function Window:mousefocus(pos)
end

function Window:mousemoved(x, y, dx, dy)
end

function Window:mousepressed(x, y, button)
end

function Window:mousereleased(button)
end

function Window:wheelmoved(x, y)
end
