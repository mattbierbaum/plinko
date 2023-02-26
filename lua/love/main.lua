local util = require('plinko.util')

local sim = require('sim')

local s, o

function draw_objects(s)
    local obj = s.objects
    for i = 1, #obj do
        local o = obj[i]
        if o.name == 'circle' then
            love.graphics.circle('line', o.pos[1], o.pos[2], o.rad)
        end
        if o.name == 'box' then
            for i, seg in ipairs(o.segments) do
                love.graphics.line(seg.p0[1], seg.p0[2], seg.p1[1], seg.p1[2])
            end
        end
    end
end



function love.draw()
    love.graphics.setColor(1, 1, 1, 1)
    o.image:replacePixels(o.data)
    love.graphics.draw(o.image)
    --love.graphics.draw(o.canvas)
    love.graphics.rectangle("fill", 0, 0, 50, 17)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(string.format("%d FPS", love.timer.getFPS()))
    draw_objects(s)
end

function love.update(dt)
    --s:step(2e4)
    s:step(10)
end

function love.load()
    love.window.setTitle('Jamba juice')
    love.window.setFullscreen(true, "desktop")
    love.graphics.setBackgroundColor(1, 1, 1)
    s, o = sim.level0()
end

