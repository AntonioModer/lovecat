_ = require('lodash')

fetch_url = (url, data, on_complete, on_fail) ->
    req = new XMLHttpRequest()
    req.onreadystatechange = ->
        return if req.readyState isnt 4
        if req.status is 200
            response = req.responseText
            response = JSON.parse(response) if response.length > 0
            # console.log(response)
            on_complete(response) if on_complete?
        else
            on_fail() if on_fail?
    req.open((if data? then "POST" else "GET"), url, true);
    req.send(data)

fetch_status = (onsuccess, onfail) ->
    fetch_url '/_lovecat_/status', null, onsuccess, onfail

fetch_view = (scope, onsuccess, onfail) ->
    fetch_url '/_lovecat_/view', 'scope='+encodeURIComponent(scope_to_lua(scope)), onsuccess, onfail

fetch_active = (onsuccess, onfail) ->
    fetch_url '/_lovecat_/active', null, onsuccess, onfail

send_update = (scope, new_val, onsuccess, onfail) ->
    fetch_url '/_lovecat_/update',
        'scope='+encodeURIComponent(scope_to_lua(scope)) +
        '&val='+encodeURIComponent(new_val), onsuccess, onfail

scope_to_lua = (scope) ->
    res = '{'
    for x in scope
        res += JSON.stringify x
        res += ', '
    res += '}'

scope_to_string = (scope) ->
    res = scope[0]
    for x in scope[1..]
        if _.isNumber(x)
            res += '[' + x + ']'
        else
            res += '.' + x
    return res

scope_to_url = (scope) ->
    encodeURI('/' + scope_to_string(scope))

subscope_to_text = (scope, subscope) ->
    subscope = subscope[scope.length...]
    res = ''
    for x in subscope[0...]
        if _.isNumber(x)
            res += '[' + x + ']'
        else
            res += '.' + x
    return res

scope_contains = (input, scope) ->
    input = input.toLowerCase()
    for word in input.split(/\s+/)
        if word is '' then continue
        ok = false
        for x in scope
            if _.isNumber(x) then x = String(x)
            if _.contains(x.toLowerCase(), word)
                ok = true
                break
        if not ok then return false
    return true

url_to_scope = (url) ->
    url = decodeURI(url)
    t1 = url.match(/^\/(.*)\[(\d+)\]$/)
    if t1
        t2 = t1[2]
        t1 = t1[1]
    else
        t1 = url[1..]
        t2 = null

    res = t1.split('.')
    res = _.filter res, (x) -> x isnt ''
    if t2? then res.push(parseInt(t2))
    return res

ele_left = (ele) ->
    ans = 0
    while ele?
        ans += ele.offsetLeft
        ele = ele.offsetParent
    return ans

ele_top = (ele) ->
    ans = 0
    while ele?
        ans += ele.offsetTop
        ele = ele.offsetParent
    return ans

format_lua_value = (kind, v) ->
    switch kind
        when 'number' then String(v)
        when 'point' then '{' + v[0] + ',' + v[1] + '}'
        when 'color' then '{' + v[0] + ',' + v[1] + ',' + v[2] + '}'
        when 'grid'
            res = '{'
            for [r,c,x] in v
                res += '{'+r+','+c+','+ JSON.stringify(x) + '},'
            res += '}'
            return res

is_leaf_scope = (scope) ->
    return false if scope.length <= 1
    last = scope[scope.length-1]
    return true if not _.isString(last)
    return false if 'A' <= last[0] and last[0] <= 'Z'
    return true

is_retina = ->
    window.devicePixelRatio > 1

scope_compare = (x, y) ->
    order =
        number: 0
        point:  1
        color:  2
        grid:   3

    if x[0] isnt y[0] then return order[x[0]] - order[y[0]]
    for i in [1...Math.max(x.length, y.length)-1]
        continue if x[i] is y[i]
        switch
            when _.isNumber(x[i]) and _.isNumber(y[i])
                return x[i] - y[i]
            when _.isNumber(x[i]) and _.isString(y[i])
                return 1
            when _.isString(x[i]) and _.isNumber(y[i])
                return -1
            when _.isString(x[i]) and _.isString(y[i])
                return -1 if x[i] < y[i]
                return 0  if x[i] == y[i]
                return 1
    return x.length - y.length

module.exports =
    fetch_status: fetch_status
    fetch_view: fetch_view
    fetch_active: fetch_active
    send_update: send_update
    ele_left: ele_left
    ele_top: ele_top
    scope_to_url: scope_to_url
    scope_to_string: scope_to_string
    url_to_scope: url_to_scope
    scope_contains: scope_contains
    format_lua_value: format_lua_value
    is_leaf_scope: is_leaf_scope
    subscope_to_text: subscope_to_text
    is_retina: is_retina
    scope_compare: scope_compare

