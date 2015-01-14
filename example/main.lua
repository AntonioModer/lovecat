function love.load()
    lovecat.watch_add(lovecat.number, function (ns, ident)
        print(ns, ident, 'is changed!')
    end)

    lovecat.watch_add(lovecat.number.ClassA.ClassB, function (ns, ident)
        print(ns, ident, 'is changed! -- wang')
    end)
end

function love.update(dt)
    -- for i=1,10 do
        lovecat.update(0.1)
        -- love.timer.sleep(0.1)
    -- end
end

function love.draw()
    local x, y = unpack(lovecat.point.Test.Class.a)
    x = (x+1)/2 * 600
    y = 600-(y+1)/2 * 600
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