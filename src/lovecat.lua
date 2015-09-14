local lovecat = {
    _VERSION     = 'lovecat v0.0.2',
    _DESCRIPTION = 'Game Parameter Editing',
    _URL         = 'https://github.com/CoffeeKitty/lovecat',
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

        ---------------

        This file may contain several frontend libraries. See LICENSE for
        details.
    ]]
}

lovecat.host = "*"
lovecat.port = 7000
lovecat.whitelist = { "127.0.0.1", "192.168.*.*" }
lovecat.active_delay = 60 -- in seconds
lovecat.save_delay = 1    -- in seconds
lovecat.data_file = 'lovecat-data.txt'
lovecat.data_load = function()
    -- if anything goes wrong, an error should be raised by assert(false)
    local path = './' .. lovecat.data_file
    if lovecat.file_exists(path) then
        lovecat.log('loading data from "' .. path .. '"...')
        return lovecat.file_read(path)
    end
end
lovecat.data_save = function(data)
    -- if anything goes wrong, an error should be raised by assert(false)
    local path = './' .. lovecat.data_file
    lovecat.log('writing data to "' .. path .. '"...')
    lovecat.file_safe_write(path, data)
end

function lovecat.init_confs()
    lovecat.number = lovecat.namespace_root({
        name = 'number',
        default = 0.5,
        data_to_file = function (ns, v) return lovecat.simple_value_to_str(v) end,
        client_to_data = function (ns, v) return v end,
        data_to_client = function (ns, v) return tostring(v) end,
    })

    lovecat.point = lovecat.namespace_root({
        name = 'point',
        default = function(ns, ident)
            if type(ident) == 'number' then
                a = 0.3
                r = 1-a
                len = a * (1-r^math.abs(ident/24)) / (1-r)
                theta = ident * (math.pi/12)
                x, y = math.cos(theta)*len, math.sin(theta)*len
                return { x, y }
            else
                x, y = math.random(), math.random()
                x, y = 2*x-1, 2*y-1
                return { x, y }
            end
        end,
        data_to_file = function (ns, v) return lovecat.simple_value_to_str(v) end,
        client_to_data = function (ns, v) return v end,
        data_to_client = function (ns, v) return '['..tostring(v[1])..','..tostring(v[2])..']' end,
    })

    lovecat.color = lovecat.namespace_root({
        name = 'color',
        default = function ()
            return { math.random() * 360, 90, 90 }
        end,
        data_to_file = function (ns, v) return lovecat.simple_value_to_str(v) end,
        client_to_data = function (ns, v) return v end,
        data_to_client = function (ns, v) return '['..tostring(v[1])..','..tostring(v[2])..','..tostring(v[3])..']' end,
    })

    lovecat.grid = lovecat.namespace_root({
        name = 'grid',
        default = {},
        data_to_file = function (ns, v) return lovecat.simple_value_to_str(v) end,
        client_to_data = function (ns, v) return v end,
        data_to_client = function (ns, v)
            res = {}
            for _, x in ipairs(v) do
                table.insert(res, '['..tostring(x[1])..','..tostring(x[2])..','..string.format('%q', x[3])..']')
            end
            return '['..table.concat(res, ',')..']'
        end,
    })
end

function lovecat.namespace_isleaf(ident)
    if type(ident) ~= 'string' then return true end
    return not (('A'):byte() <= ident:byte() and
                ('Z'):byte() >= ident:byte())
end

lovecat.namespace_meta = {
    __index = function (ns, ident)
        if lovecat.namespace_isleaf(ident) then
            local data = lovecat.data_app_get(ns, ident)
            lovecat.active_check(ns)
            return data
        else
            local node = lovecat.namespace_newnode(ns, ident)
            rawset(ns, ident, node)
            return node
        end
    end,

    __tostring = function (ns)
        return ns._CONF_.strname
    end
}

function lovecat.namespace_root(confs)
    local ns = { _CONF_ = confs }
    ns._CONF_.fullname = { ns._CONF_.name }
    ns._CONF_.strname = ns._CONF_.name
    ns._CONF_.parent = nil
    ns._CONF_.watchers = {}
    setmetatable(ns, lovecat.namespace_meta)
    table.insert(lovecat.roots, ns._CONF_.name)
    lovecat.roots_hash[ns._CONF_.name] = true
    return ns
end

function lovecat.namespace_newnode(parent, ident)
    local ns = { _CONF_ = {} }
    ns._CONF_.name = ident
    ns._CONF_.parent = parent
    ns._CONF_.watchers = {}
    ns._CONF_.fullname = lovecat.table_copy(parent._CONF_.fullname)
    table.insert(ns._CONF_.fullname, ident)
    ns._CONF_.strname = table.concat(lovecat.map(ns._CONF_.fullname, tostring), ".")
    setmetatable(ns._CONF_, { __index = parent._CONF_ })
    setmetatable(ns, lovecat.namespace_meta)
    return ns
end

function lovecat.data_scope(ns, may_create)
    local x = lovecat.data
    for _, name in ipairs(ns._CONF_.fullname) do
        if x[name] == nil then
            if not may_create then return nil end
            x[name] = {}
        end
        x = x[name]
    end
    return x
end

function lovecat.data_app_get(ns, ident)
    local data = lovecat.data_scope(ns, true)
    if data[ident] == nil then
        local new_val = ns._CONF_.default
        if type(new_val) == 'function' then
            new_val = new_val(ns, ident)
        end
        data[ident] = new_val
        lovecat.data_do_save()
        lovecat.data_inc_version()
    end
    return data[ident]
end

function lovecat.data_client_view(ns, ident)
    local res = {}

    local function enum_data(data, ns)
        if data == nil then return end
        for k,v in pairs(data) do
            if k ~= '_CONF_' then
                if lovecat.namespace_isleaf(k) then
                    local val = ns._CONF_.data_to_client(ns, v)
                    table.insert(res, {ns,k,val})
                else
                    enum_data(data[k], ns[k])
                end
            end
        end
    end

    local data = lovecat.data_scope(ns)
    if ident == nil then
        enum_data(data, ns)
    else
        if data ~= nil and data[ident] ~= nil then
            local val = ns._CONF_.data_to_client(ns, data[ident])
            table.insert(res, {ns,ident,val})
        end
    end
    return res
end

function lovecat.data_client_set(ns, ident, new_val)
    local data = lovecat.data_scope(ns)
    if data == nil then return false end
    if data[ident] == nil then return false end
    data[ident] = new_val
    lovecat.data_do_save()
    lovecat.data_inc_version()
    lovecat.watch_notify(ns, ident)
    return true
end

function lovecat.data_do_load()
    local ok, ret = pcall(lovecat.data_load)
    if not ok then
        assert(false, 'failed to load data: ' .. ret)
    end

    if ret == nil then
        lovecat.log('Warning: creating a new lovecat tree..')
        lovecat.data = {}
        lovecat.data_version = 0
        return
    end

    ok, ret = loadstring(ret, 'lovecat-data')
    if ok == nil then
        assert(false, 'data is corrupted: ' .. ret)
    end

    ok, ret = pcall(ok)
    if not ok then
        assert(false, 'data is corrupted: ' .. ret)
    end

    lovecat.data = ret
    lovecat.data_version = 0
end

function lovecat.data_actual_save()
    local tmp = {}
    local function write(str)
        table.insert(tmp, str)
    end

    write('local lovecat = {}\n\n\n-- namespaces:\n')

    local function write_namespaces(prefix, data)
        if data == nil then return end
        write(prefix .. ' = {}\n')
        for _,k in ipairs(lovecat.table_sorted_keys(data)) do
            if k ~= '_CONF_' and not lovecat.namespace_isleaf(k) then
                write_namespaces(prefix..'.'..k, data[k])
            end
        end
    end
    for _,k in ipairs(lovecat.roots) do
        write_namespaces('lovecat.'..k, lovecat.data[k])
    end
    write("\n\n-- saved parameters:\n")

    local function write_data(prefix, data, ns)
        if data == nil then return end
        for _,k in ipairs(lovecat.table_sorted_keys(data)) do
            if k ~= '_CONF_' then
                if lovecat.namespace_isleaf(k) then
                    local res = ns._CONF_.data_to_file(ns, data[k])
                    local str_k
                    if type(k) == 'number' then str_k = '['..k..']' else str_k = '.'..k end
                    write(prefix .. str_k .. ' = ' .. res .. '\n')
                else
                    write_data(prefix..'.'..k, data[k], ns[k])
                end
            end
        end
    end
    for _,k in ipairs(lovecat.roots) do
        write_data('lovecat.'..k, lovecat.data[k], lovecat[k])
    end

    write('\n\n')

    write [[
-- The following code tries to make the data file a drop-in
-- replacement for lovecat.lua

local function make_tostring(prefix, node)
    setmetatable(node, {__tostring=function() return prefix end})
    for ident,v in pairs(node) do
        if prefix == '' or
           (type(ident) == 'string' and
            ('A'):byte() <= ident:byte() and
            ('Z'):byte() >= ident:byte()) then
            local new_prefix
            if prefix == '' then
                new_prefix = ident
            else
                new_prefix = prefix..'.'..ident
            end
            make_tostring(new_prefix, v)
        end
    end
end
make_tostring('', lovecat)

lovecat.update       = function() end
lovecat.watch_add    = function() end
lovecat.watch_remove = function() end
lovecat.set_default  = function() end
lovecat.reload       = function() end

return lovecat
]]

    local data = table.concat(tmp)
    local ok, msg = pcall(lovecat.data_save, data)
    if not ok then
        lovecat.log('Error: failed to save data: ' .. msg)
    end
end

-- Will actually write to disk after a delay
function lovecat.data_do_save()
    if lovecat.save_timer == nil then
        lovecat.save_timer = lovecat.clock + lovecat.save_delay
    end
end

function lovecat.data_save_timer_reset()
    if lovecat.save_timer then
        lovecat.save_timer = nil
        lovecat.data_actual_save()
    end
end

function lovecat.data_save_timer_check()
    if lovecat.save_timer and lovecat.save_timer < lovecat.clock then
        lovecat.save_timer = nil
        lovecat.data_actual_save()
    end
end

function lovecat.data_inc_version()
    lovecat.data_version = lovecat.data_version + 1
end


function lovecat.active_reset()
    lovecat.active_expire = {}
    lovecat.active_heap = {}
    lovecat.active_heap_pos = {}
    lovecat.active_version = 0
end

function lovecat.active_fixheap(x)
    local H = lovecat.active_heap
    local P = lovecat.active_heap_pos
    local K = lovecat.active_expire

    local function swap(i, j)
        P[H[i]], P[H[j]] = j, i
        H[i], H[j] = H[j], H[i]
    end

    local function move_up(x)
        while x > 1 do
            local p = math.floor(x/2)
            if K[H[x]] < K[H[p]] then
                swap(x, p)
            end
            x = p
        end
    end

    local function move_down(x)
        while true do
            local m = x
            local l, r = x+x, x+x+1
            if H[l] ~= nil and K[H[l]] < K[H[m]] then m = l end
            if H[r] ~= nil and K[H[r]] < K[H[m]] then m = r end
            if m == x then break end
            swap(m, x)
            x = m
        end
    end

    move_up(x)
    move_down(x)
end

function lovecat.active_set_expire(ns, expire)
    if expire == nil then
        expire = lovecat.clock + lovecat.active_delay
    end

    lovecat.active_expire[ns] = expire

    if lovecat.active_heap_pos[ns] then
        lovecat.active_fixheap(lovecat.active_heap_pos[ns])
    else
        local p = #lovecat.active_heap+1
        lovecat.active_heap_pos[ns] = p
        lovecat.active_heap[p] = ns
        lovecat.active_fixheap(p)
        lovecat.active_inc_version()
    end
end

function lovecat.active_update()
    -- lovecat.log('active heap size:', #lovecat.active_heap)
    while #lovecat.active_heap>0 do
        local ns = lovecat.active_heap[1]
        local t = lovecat.active_expire[ns]
        if t > lovecat.clock then break end

        local sz = #lovecat.active_heap
        local last_ns = lovecat.active_heap[sz]
        lovecat.active_heap[1] = last_ns
        lovecat.active_heap[sz] = nil
        lovecat.active_heap_pos[last_ns] = 1
        lovecat.active_heap_pos[ns] = nil
        lovecat.active_expire[ns] = nil

        if sz > 1 then lovecat.active_fixheap(1) end
        lovecat.active_inc_version()
    end
end

function lovecat.active_inc_version()
    lovecat.active_version = lovecat.active_version + 1
end

function lovecat.active_check(ns)
    local inf = 1000000000
    if #ns._CONF_.watchers > 0 then
        lovecat.active_set_expire(ns, inf)
    else
        lovecat.active_set_expire(ns)
    end
end

function lovecat.watch_add(ns, func)
    assert(func ~= nil)
    for _, x in ipairs(ns._CONF_.watchers) do
        if x == func then return end
    end
    table.insert(ns._CONF_.watchers, func)
    lovecat.active_check(ns)
end

-- if `func==nil`, then remove all watchers associated at `ns`
function lovecat.watch_remove(ns, func, in_reset)
    if func == nil then
        for k, x in pairs(ns._CONF_.watchers) do
            ns._CONF_.watchers[k] = nil
        end
        if not in_reset then lovecat.active_check(ns) end
    else
        for k, x in ipairs(ns._CONF_.watchers) do
            if x == func then
                table.remove(ns._CONF_.watchers, k)
                if not in_reset then lovecat.active_check(ns) end
                return
            end
        end
    end
end

function lovecat.watch_reset()
    local function reset_ns(ns)
        lovecat.watch_remove(ns, nil, true)
        for k,v in pairs(ns) do
            if k ~= '_CONF_' then
                assert(not lovecat.namespace_isleaf(k))
                reset_ns(v)
            end
        end
    end
    for k, root in ipairs(lovecat.roots) do
        reset_ns(lovecat[root])
    end
end

function lovecat.watch_notify(ns, ident)
    local function _notify(x)
        for _, func in ipairs(x._CONF_.watchers) do
            local ok, err = pcall(func, ns, ident)
            if not ok then
                lovecat.log('Error while notifying watcher:', err)
            end
        end
    end
    local x = ns
    while x ~= nil do
        _notify(x)
        x = x._CONF_.parent
    end
end

function lovecat.reload()
    lovecat.clock = 0
    lovecat.instance_renew()
    lovecat.active_reset()
    lovecat.data_do_load()
    lovecat.watch_reset()
    lovecat.data_save_timer_reset()
end

function lovecat.start_server()
    lovecat.server = assert(require('socket').bind(lovecat.host, lovecat.port))
    lovecat.addr, lovecat.port = lovecat.server:getsockname()
    lovecat.server:settimeout(0)
    lovecat.server_started = true
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
    if not lovecat.server_started then lovecat.start_server() end
    lovecat.clock = lovecat.clock + dt
    lovecat.data_save_timer_check()
    lovecat.active_update()
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

function lovecat.instance_renew()
    lovecat.instance_num = os.time()
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
    local str = "[lovecat] " .. table.concat(lovecat.map({...}, tostring), " ")
    print(str)
end

function lovecat.file_exists(filename)
    local f = io.open(filename)
    if f then
        io.close(f)
        return true
    else
        return false
    end
end

function lovecat.file_read(path)
    local file = io.input(path)
    local ans = file:read('*a')
    file:close()
    assert(ans, 'cannot read file: "' .. path .. '"')
    return ans
end

function lovecat.file_safe_write(path, content)
    local path_tmp = path .. '.tmp'
    local out = io.output(path_tmp)
    out:write(content)
    out:close()

    local ok, err = os.rename(path_tmp, path)
    if not ok then
        -- for Windows
        local path_ori = path .. '.ori'
        os.remove(path_ori)
        local ok, err = os.rename(path, path_ori)
        if not ok then
            assert(false, 'unable to write to "'..path..'": ' .. err)
        end
        local ok, err = os.rename(path_tmp, path)
        if not ok then
            os.rename(path_ori, path)
            assert(false, 'unable to write to "'..path..'": ' .. err)
        else
            os.remove(path_ori)
        end
    end
end

function lovecat.static_file(filename)
    return function()
        return lovecat.file_read(filename)
    end
end

function lovecat.table_copy(tbl)
    local res = {}
    for k,v in pairs(tbl) do
        res[k]=v
    end
    return res
end

function lovecat.table_repeated(num, func_or_const)
    local res = {}
    for i=1,num do
        if type(func_or_const) == 'function' then
            table.insert(res, func_or_const())
        else
            table.insert(res, func_or_const)
        end
    end
    return res
end

function lovecat.table_sorted_keys(tbl)
    local res = {}
    for k,v in pairs(tbl) do table.insert(res, k) end
    table.sort(res, function(x, y)
        if type(x) == 'number' and type(y) == 'number' then
            return x < y
        elseif type(x) == 'string' and type(y) == 'string' then
            return x < y
        else
            return type(x) > type(y)
        end
    end)
    return res
end

function lovecat.simple_value_to_str(val)
    if type(val) == 'number' then
        return tostring(val)
    elseif type(val) == 'string' then
        return string.format('%q', val)
    elseif type(val) == 'table' then
        return '{'..table.concat(lovecat.map(val, lovecat.simple_value_to_str), ', ')..'}'
    end
end

-- `ident` may be `nil`
function lovecat.ns_to_json(ns, ident)
    local res = lovecat.map(ns._CONF_.fullname, function (x) return string.format('%q', x) end)
    res = table.concat(res, ', ')
    if type(ident) == 'number' then
        res = res .. ', ' .. ident
    elseif type(ident) == 'string' then
        res = res .. ', ' .. string.format('%q', ident)
    end
    res = '[' .. res .. ']'
    return res
end

lovecat.roots = {}
lovecat.roots_hash = {}
lovecat.init_confs()

lovecat.pages = {}
lovecat.pages_mime = {}

lovecat.pages_mime['_lovecat_/status'] = 'application/json'
lovecat.pages['_lovecat_/status'] = function (lovecat, req)
    return '{ "instance_num": ' .. lovecat.instance_num ..
           ', "data_version": ' .. lovecat.data_version ..
           ', "active_version": ' .. lovecat.active_version .. ' }'
end

lovecat.pages_mime['_lovecat_/view'] = 'application/json'
lovecat.pages['_lovecat_/view'] = function (lovecat, req)
    local req_scope = req.parsedbody['scope']
    req_scope = load('return '..req_scope)()
    local results

    if not lovecat.roots_hash[req_scope[1]] then return '[]' end
    local ns = lovecat[req_scope[1]]
    if #req_scope>1 then
        for i=2,#req_scope-1 do
            assert(not lovecat.namespace_isleaf(req_scope[i]))
            ns = ns[req_scope[i]]
        end
        if lovecat.namespace_isleaf(req_scope[#req_scope]) then
            results = lovecat.data_client_view(ns, req_scope[#req_scope])
        else
            ns = ns[req_scope[#req_scope]]
            results = lovecat.data_client_view(ns)
        end
    else
        results = lovecat.data_client_view(ns)
    end

    local json = {}
    for _,x in ipairs(results) do
        table.insert(json,
            '{ "k": ' .. lovecat.ns_to_json(x[1], x[2]) .. ', ' ..
              '"v": ' .. x[3] .. ' }')
    end
    json = table.concat(json, ', ')
    json = '[' .. json .. ']'

    return json
end

lovecat.pages_mime['_lovecat_/update'] = 'application/json'
lovecat.pages['_lovecat_/update'] = function (lovecat, req)
    local req_scope = req.parsedbody['scope']
    local req_val = req.parsedbody['val']
    req_scope = load('return '..req_scope)()
    req_val = load('return '..req_val)()

    if not lovecat.roots_hash[req_scope[1]] then
        lovecat.log('invalid client update')
        return
    end
    local ns = lovecat[req_scope[1]]
    for i=2,#req_scope-1 do
        if lovecat.namespace_isleaf(req_scope[i]) then
            lovecat.log('invalid client update')
            assert(false)
        end
        ns = ns[req_scope[i]]
    end
    local ident = req_scope[#req_scope]

    if not lovecat.namespace_isleaf(ident) then
        lovecat.log('invalid client update')
        assert(false)
    end

    local new_val = ns._CONF_.client_to_data(ns, req_val)
    if not lovecat.data_client_set(ns, ident, new_val) then
        lovecat.log('invalid client update')
        assert(false)
    end

    return ''
end

lovecat.pages_mime['_lovecat_/active'] = 'application/json'
lovecat.pages['_lovecat_/active'] = function (lovecat, req)
    local json = {}
    for ns,_ in pairs(lovecat.active_expire) do
        table.insert(json, lovecat.ns_to_json(ns))
    end
    json = table.concat(json, ', ')
    json = '[' .. json .. ']'
    return json
end

lovecat.pages['_default'] = [[
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <title>lovecat</title>
        <link href="/_lovecat_/app.css" rel="stylesheet">
    </head>
    <body>
        <div id='page'></div>
        <script src="/_lovecat_/app.js"></script>
        ADDITIONAL_SCRIPT
    </body>
    </html>
]]

--==--==--==-- CUT! --==--==--==--

-- the code below are for development,
-- and will be replaced automatically by a releasing script

local additional_script = [[
    <script>document.write('<script src="http://' + (location.host || 'localhost').split(':')[0] + ':35729/livereload.js?snipver=1"></' + 'script>')</script>
]]

lovecat.pages["_default"] = lovecat.pages["_default"]:gsub('ADDITIONAL_SCRIPT', additional_script)

lovecat.pages["_lovecat_/app.css"] = lovecat.static_file('../less/generated.css')
lovecat.pages_mime["_lovecat_/app.css"] = 'text/css'
lovecat.pages["_lovecat_/app.js"] = lovecat.static_file('../cjsx/generated.js')

return lovecat