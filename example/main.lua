local TileSize = 25

function love.load()
    lovecat.reload()

    lovecat.watch_add(lovecat.grid.Scene, function()
        build_scene()
    end)

    lovecat.watch_add(lovecat.number.Shape, function(ns, ident)
        if ns == lovecat.number.Shape and ident == 'player_radius' then
            build_scene()
        end
    end)

    world = love.physics.newWorld()
    world:setCallbacks(
        function(a, b, contact)
            local other
            if a == player_sensor then
                other = b
            elseif b == player_sensor then
                other = a
            else
                return
            end

            if other:getBody():getUserData().type == 'wall' then
                player_support[other:getBody()] = true
            end
        end,
        function(a, b, contact)
            local other
            if a == player_sensor then
                other = b
            elseif b == player_sensor then
                other = a
            else
                return
            end

            if other:getBody():getUserData().type == 'wall' then
                player_support[other:getBody()] = nil
            end
        end,
        function(a, b, contact)
            local other
            if a == player_body then
                other = b
            elseif b == player_body then
                other = a
            else
                return
            end

            if other:getBody():getUserData().type == 'coin' then
                coins_eaten[other:getBody()] = true
                coins[other:getBody()] = nil
                contact:setEnabled(false)
                other:getBody():destroy()
            end
        end,
        nil
    )

    coins = {}
    walls = {}
    player = nil

    build_scene()

    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setBackgroundColor(255,255,255)
end

function love.update(dt)
    lovecat.update(dt)

    world:setGravity(0, lovecat_range(lovecat.number.Physics.gravity, 0, 10000))
    if player ~= nil then
        player:setLinearDamping(lovecat_range(lovecat.number.Physics.player_damping, 0, 10))
        player:setMass(lovecat_range(lovecat.number.Physics.player_mass, 0, 1))
    end

    local function push_player(dx, dy)
        if player == nil then return end
        player:applyLinearImpulse(dx, dy)
    end

    local move_impulse = lovecat_range(lovecat.number.Physics.move_impulse, 100, 600)
    if love.keyboard.isDown('left') then
        push_player(-move_impulse*dt, 0)
    elseif love.keyboard.isDown('right') then
        push_player( move_impulse*dt, 0)
    end

    if jump_cooldown == nil then
        jump_cooldown = 0
    else
        jump_cooldown = jump_cooldown - dt
    end

    local jump_impulse = lovecat_range(lovecat.number.Physics.jump_impulse, 100, 500)
    if jump_signal and jump_cooldown <= 0 and player_is_supported() then
        push_player(0, -jump_impulse)
        jump_cooldown = 0.2
    end
    jump_signal = false

    world:update(dt)

    -- https://love2d.org/forums/viewtopic.php?f=4&t=77893
    collectgarbage()
end

function love.draw()
    local tile_margin = lovecat_range(lovecat.number.Graphics.tile_margin, 0, 10)
    for _, wall in ipairs(walls) do
        local x, y = wall:getWorldCenter()
        if wall:getUserData().subtype == 'normal' then
            lovecat_color(lovecat.color.Graphics.wall)
        else
            lovecat_color(lovecat.color.Graphics.wall_alt)
        end
        love.graphics.rectangle('fill',
            (x-TileSize/2+tile_margin), (y-TileSize/2+tile_margin),
            (TileSize-tile_margin*2),   (TileSize-tile_margin*2))
    end

    for coin in pairs(coins) do
        lovecat_color(lovecat.color.Graphics.coin)
        local x, y = coin:getWorldCenter()

        lovecat_shape(lovecat.point.Shape.Coin, 8, function(xx,yy)
            local size = lovecat_range(lovecat.number.Graphics.coin_size, TileSize/6, TileSize/2)
            xx, yy = xx*size, -yy*size
            return x+xx, y+yy
        end)
    end

    if player ~= nil then
        local x, y = player:getWorldCenter()
        lovecat_color(lovecat.color.Graphics.player)
        love.graphics.circle('fill', x, y, player_radius+tile_margin, 20)
    end

    if player_is_supported then
        lovecat_color(lovecat.color.Graphics.hud)
        love.graphics.print('Move: [left] [right]   |   Jump: [space]   |    Reload: [r]', 10, 10)
        if player_is_supported() then
            love.graphics.print('player is on the ground', 10, 35)
        else
            love.graphics.print('player is NOT on the ground', 10, 35)
        end
        love.graphics.print('score: ' .. 10 * player_coins(), 10, 60)
    end
end

function love.keypressed(key)
    if key == 'r' then
        cupid.reload()
    elseif key == ' ' then
        jump_signal = true
    end
end

function player_is_supported()
    for _ in pairs(player_support) do
        return true
    end
    return false
end

function player_coins()
    local ans = 0
    for _ in pairs(coins_eaten) do
        ans = ans + 1
    end
    return ans
end

function build_scene()
    print('will rebuild scene..')

    local tiles = lovecat.grid.Scene.tiles

    for _, x in ipairs(walls) do x:destroy() end
    walls = {}

    for x in pairs(coins) do x:destroy() end
    coins = {}
    coins_eaten = {}

    if player ~= nil then
        player:destroy()
        player = nil
    end
    player_support = {}

    local function add_wall(subtype, r, c)
        local shape = love.physics.newRectangleShape(TileSize, TileSize)
        local body = love.physics.newBody(world, TileSize * (c+0.5), TileSize * (r+0.5))
        body:setUserData({type='wall', subtype=subtype})
        local fixture = love.physics.newFixture(body, shape)
        table.insert(walls, body)
    end

    local function add_coin(r, c)
        local shape = love.physics.newCircleShape(TileSize * 0.3)
        local body = love.physics.newBody(world, TileSize * (c+0.5), TileSize * (r+0.5))
        body:setUserData({type='coin'})
        local fixture = love.physics.newFixture(body, shape)
        coins[body] = true
    end

    local function add_player(r, c)
        local radius = lovecat_range(lovecat.number.Shape.player_radius, 3, 25)
        local shape = love.physics.newCircleShape(radius)
        local body = love.physics.newBody(world, TileSize * (c+0.5), TileSize * (r+1) - radius, 'dynamic')
        body:setUserData({type='player'})
        body:setFixedRotation(true)
        local fixture = love.physics.newFixture(body, shape)
        player = body
        player_body = fixture
        player_radius = radius

        local shape = love.physics.newRectangleShape(0, radius, radius, 1)
        local fixture = love.physics.newFixture(body, shape, 0)
        fixture:setSensor(true)
        player_sensor = fixture
    end

    for _, tile in ipairs(tiles) do
        local r, c, x = unpack(tile)
        if x == 'w' then
            add_wall('normal', r,c)
        elseif x == 'm' then
            add_wall('alternative', r,c)
        elseif x == 'P' then
            if player == nil then
                add_player(r, c)
            end
        elseif x == 'C' then
            add_coin(r, c)
        end
    end
end

function lovecat_shape(ns, num, func)
    local curve = {}
    for i=1,num do
        local x, y = unpack(ns[i])
        x, y = func(x, y)
        table.insert(curve, x)
        table.insert(curve, y)
    end
    love.graphics.polygon('fill', curve)
end

function lovecat_color(x)
    love.graphics.setColor(HSV(unpack(x)))
end

function lovecat_range(x, lower, upper)
    return lower + (upper-lower)*x
end

function HSV(h, s, v)
    h, s, v = h/360*6, s/100, v/100
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end return (r+m)*255,(g+m)*255,(b+m)*255
end

