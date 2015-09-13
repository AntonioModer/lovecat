package.path = '../src/?.lua;../?.lua;?.txt;' .. package.path

lovecat = require 'lovecat'
-- lovecat = require 'lovecat-data'
require 'cupid'

function love.conf(t)
    t.window.fsaa = 16
end