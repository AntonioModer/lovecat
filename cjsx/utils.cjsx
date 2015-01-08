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
    fetch_url '/_lovecat_/view', 'scope='+encodeURI(scope_to_lua(scope)), onsuccess, onfail

send_update = (scope, new_val) ->
    fetch_url '/_lovecat_/update',
        'scope='+encodeURI(scope_to_lua(scope)) +
        '&val='+encodeURI(new_val)

scope_to_lua = (scope) ->
    res = '{'
    for x in scope
        res += JSON.stringify x
        res += ', '
    res += '}'

scope_to_url = (scope) ->
    res = ''
    for x in scope
        res += x
        res += '.'
    encodeURI('/' + res)

ele_left = (ele) ->
    ans = 0
    while ele?
        ans += ele.offsetLeft
        ele = ele.offsetParent
    return ans

module.exports =
    fetch_status: fetch_status
    fetch_view: fetch_view
    send_update: send_update
    ele_left: ele_left
