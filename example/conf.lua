package.path = '../src/?.lua;?.txt;' .. package.path

lovecat = require 'lovecat'
-- lovecat = require 'lovecat-data'
require 'cupid'

-- to facilitate running the demo
lovecat.whitelist = { '*.*.*.*' }
lovecat.data_load = function()
    local path = love.filesystem.getSourceBaseDirectory() .. '/' .. lovecat.data_file
    if lovecat.file_exists(path) then
        lovecat.log('loading data from "' .. path .. '"...')
        return lovecat.file_read(path)
    end

    if love.filesystem.isFile(lovecat.data_file) then
        lovecat.log('loading data "' .. lovecat.data_file .. '" with love.filesystem...')
        return love.filesystem.read(lovecat.data_file)
    end
end
lovecat.data_save = function(data)
    local path = love.filesystem.getRealDirectory('main.lua') .. '/' .. lovecat.data_file
    lovecat.log('trying to write data to"' .. path .. '"...')
    ok = pcall(lovecat.file_safe_write, path, data)
    if ok then return end

    local path = love.filesystem.getSourceBaseDirectory() .. '/' .. lovecat.data_file
    lovecat.log('writing data to "' .. path .. '"...')
    lovecat.file_safe_write(path, data)
end

function love.conf(t)
    t.version = '0.9.2'
    t.window.fsaa = 16
end