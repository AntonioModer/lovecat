function love.update(dt)
    lovecat.update(dt)
end

function love.draw()
    love.graphics.circle('line', 300, 390, lovecat.number.ClassA.ClassB.size * 30, 30)
end

function love.keypressed(key)
    if key == 'r' then
        cupid.reload()
    end
end