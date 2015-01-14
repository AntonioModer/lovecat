function love.load()
    lovecat.watch_add(lovecat.number, function (ns, ident)
        print(ns, ident, 'is changed!')
    end)

--[[
    lovecat.watch_add(lovecat.number.ClassA.ClassB, function (ns, ident)
        print(ns, ident, 'is changed! -- wang')
    end)
]]

    require 'catmull-rom'
end

function love.update(dt)
    -- for i=1,10 do
        lovecat.update(dt)
        -- love.timer.sleep(0.1)
    -- end
end

function vector(ns, cnt)
    local res = {}
    for i=1,cnt do
        table.insert(res, ns[i])
    end
    return res
end

function curve(num, pnt_func)
    local all = {}

    local function wrap(k)
        if k < 1 then return num+k end
        if k > num then return k-num end
        return k
    end

    for i = 1, num do
        local x0, y0 = pnt_func(wrap(i-2))
        local x1, y1 = pnt_func(wrap(i-1))
        local x2, y2 = pnt_func(i)
        local x3, y3 = pnt_func(wrap(i+1))

        local res = catmull_rom(x0,y0, x1,y1, x2,y2, x3,y3, 1)
        for i = 1,#res-2 do
            table.insert(all, res[i])
        end
    end

    love.graphics.line(all)
end

function lovecat_curve(num, ns, func)
    local tmp = vector(ns, num)
    curve(num, function (i) return func(unpack(tmp[i])) end)
end

function love.draw()
    -- love.graphics.setLineJoin('none')
    love.graphics.setLineJoin('miter')
    love.graphics.setLineWidth(lovecat.number.Test.Curve.line_width * 5 + 0.5)
    lovecat_curve(10, lovecat.point.Test.CurveC, function(x, y)
        local x = (x+1)/2 * 600
        local y = 600-(y+1)/2 * 600
        return x, y
    end )

    local x, y = unpack(lovecat.point.Test.Miao.miao)
    local x = (x+1)/2 * 600
    local y = 600-(y+1)/2 * 600
    love.graphics.circle('line', x, y, 10, 30)

    local x = lovecat.number.ClassA.ClassB.x * 600
    local y = lovecat.number.ClassA.ClassB.y * 800
    local size = 20 + lovecat.number.ClassA.ClassB.size * 100
    love.graphics.circle('line', x, y, size, 30)

    local x = lovecat.number.ClassA.ClassC.x * 600
    local y = lovecat.number.ClassA.ClassC.y * 800
    local size = 20 + lovecat.number.ClassA.ClassC.size * 100
    love.graphics.circle('line', x, y, size, 30)
end

function love.keypressed(key)
    if key == 'r' then
        cupid.reload()
    end
end