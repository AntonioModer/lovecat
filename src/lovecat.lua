local lovecat = {
    _VERSION     = 'lovecat v0.0.1',
    _DESCRIPTION = 'Web-based Parameter Tuning for Love2d',
    _URL         = '', -- TBD
    _LICENSE     = [[
        MIT LICENSE

        Copyright (c) 2015 Yucheng Zhang

        Permission is hereby granted, free of charge, to any person obtaining a
        copy of this software and associated documentation files (the
        "Software"), to deal in the Software without restriction, including
        without limitation the rights to use, copy, modify, merge, publish,
        distribute, sublicense, and/or sell copies of the Software, and to
        permit persons to whom the Software is furnished to do so, subject to
        the following conditions:

        The above copyright notice and this permission notice shall be included
        in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
        IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
        CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
        TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
        SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ]]
}

lovecat.host = "*"
lovecat.port = 8000
lovecat.whitelist = { "127.0.0.1", "192.168.*.*" }

function lovecat.init()
    lovecat.server = assert(require('socket').bind(lovecat.host, lovecat.port))
    lovecat.addr, lovecat.port = lovecat.server:getsockname()
    lovecat.server:settimeout(0)
    lovecat.inited = true
end

function lovecat.onrequest(req, client)
    local page = req.parsedurl.path
    if not lovecat.pages[page] then
        page = '_default'
    end
    local res = lovecat.pages[page]
    local mime = lovecat.pages_mime[page] or 'text/html'
    if type(res) == 'function' then
        local success, err = pcall(function()
            res = res(lovecat, req)
        end)
        if not success then
            lovecat.log(err)
            res = "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\n\r\n" .. err
            return res
        end
    end
    res = "HTTP/1.1 200 OK\r\nContent-Type: " .. mime .. "\r\n\r\n" .. res
    return res
end

function lovecat.onconnect(client)
    -- Create request table
    local requestptn = "(%S*)%s*(%S*)%s*(%S*)"
    local req = {}
    req.socket = client
    req.addr, req.port = client:getsockname()
    req.request = client:receive()
    req.method, req.url, req.proto = req.request:match(requestptn)
    req.headers = {}
    while 1 do
        local line = client:receive()
        if not line or #line == 0 then break end
        local k, v = line:match("(.-):%s*(.*)$")
        req.headers[k] = v
    end
    if req.headers["Content-Length"] then
        req.body = client:receive(req.headers["Content-Length"])
    end
    -- Parse body
    req.parsedbody = {}
    if req.body then
        for k, v in req.body:gmatch("([^&]-)=([^&^#]*)") do
            req.parsedbody[k] = lovecat.unescape(v)
        end
    end
    -- Parse request line's url
    req.parsedurl = lovecat.parseurl(req.url)
    -- Handle request; get data to send
    local data, index = lovecat.onrequest(req), 0
    -- Send data
    while index < #data do
        index = index + client:send(data, index)
    end
    -- Clear up
    client:close()
end

function lovecat.update(dt)
    if not lovecat.inited then lovecat.init() end
    while 1 do
        local client = lovecat.server:accept()
        if not client then break end
        client:settimeout(2)
        local addr = client:getsockname()
        if lovecat.checkwhitelist(addr) then
            xpcall(function() lovecat.onconnect(client) end, function() end)
        else
            lovecat.log("got non-whitelisted connection attempt: ", addr)
            client:close()
        end
    end
end

function lovecat.checkwhitelist(addr)
    if lovecat.whitelist == nil then return true end
    for _, a in pairs(lovecat.whitelist) do
        local ptn = "^" .. a:gsub("%.", "%%."):gsub("%*", "%%d*") .. "$"
        if addr:match(ptn) then return true end
    end
    return false
end

function lovecat.unescape(str)
    local f = function(x) return string.char(tonumber("0x"..x)) end
    return (str:gsub("%+", " "):gsub("%%(..)", f))
end

function lovecat.parseurl(url)
    local res = {}
    res.path, res.search = url:match("/([^%?]*)%??(.*)")
    res.query = {}
    for k, v in res.search:gmatch("([^&^?]-)=([^&^#]*)") do
        res.query[k] = lovecat.unescape(v)
    end
    return res
end

function lovecat.map(t, fn)
    local res = {}
    for k, v in pairs(t) do res[k] = fn(v) end
    return res
end

function lovecat.log(...)
    local str = "[lovecat] " .. table.concat(lovebird.map({...}, tostring), " ")
    print(str)
end

function lovecat.static_file(filename)
    return function()
        return io.input(filename):read('*a')
    end
end

lovecat.pages = {}
lovecat.pages_mime = {}

--==--==--==-- CUT! --==--==--==--

-- the code below are for development,
-- and will be replaced automatically by a releasing script

lovecat.pages["_default"] = [[
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>lovecat</title>
        <link href="/_lovecat_/app.css" rel="stylesheet">
    </head>
    <body>
        <div id='page'></div>
        <script src="/_lovecat_/app.js"></script>
        <script>document.write('<script src="http://' + (location.host || 'localhost').split(':')[0] + ':35729/livereload.js?snipver=1"></' + 'script>')</script>
    </body>
    </html>
]]

lovecat.pages["_lovecat_/app.css"] = lovecat.static_file('../css/app.css')
lovecat.pages_mime["_lovecat_/app.css"] = 'text/css'
lovecat.pages["_lovecat_/app.js"] = lovecat.static_file('../cjsx/generated.js')

return lovecat