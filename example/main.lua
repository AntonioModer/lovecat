function love.update(dt)
    --while true do
        lovecat.update(dt)
    --    love.timer.sleep(0.1)
    --end
end

function love.draw()
    local x = lovecat.number.ClassA.ClassB.x * 600
    local y = lovecat.number.ClassA.ClassB.y * 800
    local size = 20 + lovecat.number.ClassA.ClassB.size * 100
    love.graphics.circle('line', x, y, size, 30)
end

function love.keypressed(key)
    if key == 'r' then
        cupid.reload()
    end
end