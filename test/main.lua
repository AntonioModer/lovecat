package.path = '../src/?.lua;' .. package.path

function love.update(dt)
    require('lovecat').update(dt)
end
