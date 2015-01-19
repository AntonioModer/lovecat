React = require('react')
widgets = require('./widgets')
_ = require('lodash')
utils = require('./utils')
Color = require('color')

grid_size = 33

build_char_color = ->
    C = {}
    D = {}
    color = Color()
    hsv = (h,s,v) ->
        color.hsv(h,s,v).rgbString()

    # digits
    for c in [48..58]
        x = 360 / 10 * (c-48)
        C[String.fromCharCode(c)] = hsv(x, 0, 98)
        D[String.fromCharCode(c)] = hsv(x, 0, 40)

    # upper-case
    for c in [65..91]
        x = 360 / 26 * (c-65)
        C[String.fromCharCode(c)] = hsv(x, 55, 100)
        D[String.fromCharCode(c)] = hsv(x, 70, 60)

    # lower-case
    for c in [97..123]
        x = 360 / 26 * (c-97)
        C[String.fromCharCode(c)] = hsv(x, 10, 100)
        D[String.fromCharCode(c)] = hsv(x, 60, 80)

    # others
    others = [].concat([33...48], [58...65], [91...97], [123...127])
    console.log others.length
    for i in [0...others.length]
        c = String.fromCharCode(others[i])
        x = 360 / others.length * i
        C[c] = hsv(x, 100, 50)
        D[c] = hsv(x, 0, 100)

    return [C,D]

[char_colors_bg, char_colors_fg] = build_char_color()

SingleGridPage = React.createClass
    getInitialState: ->
        lower_r: -30
        upper_r: 30
        lower_c: -30
        upper_c: 30

        view_r: null
        view_c: null
        view_r0: 0
        view_c0: 0

        sel_A: null
        sel_B: null

        data_hash: null

        last_move: [0, 1]

    build_data_hash: (data) ->
        data_hash = {}
        for x in data
            [r,c,s] = x
            if not data_hash[r]?
                data_hash[r] = {}
            data_hash[r][c] = s
        @setState data_hash: data_hash

    get_data: (r, c) ->
        return ' ' if not @state.data_hash[r]?
        return ' ' if not @state.data_hash[r][c]?
        return @state.data_hash[r][c]

    set_view_size: ->
        view_width = document.documentElement.clientWidth
        view_height = document.documentElement.clientHeight
        view_width -= 60
        view_height -= 185
        view_r = Math.floor(view_height/grid_size)
        view_c = Math.floor(view_width /grid_size)
        if view_r isnt @state.view_r or view_c isnt @state.view_c
            @setState
                view_r: view_r
                view_c: view_c
                sel_A: [0, 0]
                sel_B: [0, 0]

    componentWillMount: ->
        do @set_view_size
        @build_data_hash(@props.data)

    componentWillReceiveProps: (new_props) ->
        @build_data_hash(new_props.data)

    componentDidMount: ->
        do @set_view_size
        window.addEventListener('resize', @set_view_size)
        window.addEventListener('mousedown', @onmousedown)
        window.addEventListener('keypress', @onkeypress)
        window.addEventListener('keydown', @onkeydown)

    componentDidUnmount: ->
        window.removeEventListener('resize', @set_view_size)
        window.removeEventListener('mousedown', @onmousedown)
        window.removeEventListener('keypress', @onkeypress)
        window.removeEventListener('keydown', @onkeydown)

    mouse_to_view: (evt) ->
        r = evt.pageY - utils.ele_top(@refs.table.getDOMNode()) - 1
        c = evt.pageX - utils.ele_left(@refs.table.getDOMNode()) - 1
        r = Math.floor(r/grid_size)
        c = Math.floor(c/grid_size)
        return [r,c]

    onmousedown: (evt) ->
        [r,c] = @mouse_to_view(evt)
        if r < 0 then return
        if r >= @state.view_r then return
        if c < 0 then c = 0
        if c >= @state.view_c then return

        @setState
            sel_A: [r,c]
            sel_B: [r,c]
        evt.preventDefault()
        window.addEventListener('mousemove', @onmousemove)
        window.addEventListener('mouseup', @onmouseup)

    onmousemove: (evt) ->
        [r,c] = @mouse_to_view(evt)
        if r < 0 then r = 0
        if r >= @state.view_r then r = @state.view_r-1
        if c < 0 then c = 0
        if c >= @state.view_c then c = @state.view_c-1
        @setState sel_B: [r,c]

    onmouseup: (evt) ->
        window.removeEventListener('mousemove', @onmousemove)
        window.removeEventListener('mouseup', @onmouseup)

    move_sel: (dr, dc, do_not_save_move) ->
        @setState
            sel_A: [@state.sel_A[0]+dr, @state.sel_A[1]+dc]
            sel_B: [@state.sel_B[0]+dr, @state.sel_B[1]+dc]
        if not do_not_save_move
            @setState
                last_move: [dr, dc]

    # for special keys
    onkeydown: (evt) ->
        switch
            when evt.key == 'Down' or evt.keyIdentifier == 'Down'
                @move_sel(1, 0)
            when evt.key == 'Up' or evt.keyIdentifier == 'Up'
                @move_sel(-1, 0)
            when evt.key == 'Left' or evt.keyIdentifier == 'Left'
                @move_sel(0, -1)
            when evt.key == 'Right' or evt.keyIdentifier == 'Right'
                @move_sel(0, 1)
            when evt.key == 'Backspace' or evt.keyIdentifier == 'U+0008'
                if @state.last_move?
                    @move_sel(-@state.last_move[0], -@state.last_move[1], true)
                    [r1,c1,r2,c2] = @get_sel_box_data()
                    res = @fill_data(r1,c1, r2,c2, -> ' ')
                    @props.onchange @props.scope, res
            else
                return
        evt.preventDefault()

    # for grid cotents
    onkeypress: (evt) ->
        ascii = evt.which
        return if not (32 <= ascii and ascii <= 126)
        ch = String.fromCharCode(evt.which)

        [r1,c1,r2,c2] = @get_sel_box_data()
        res = @fill_data(r1,c1, r2,c2, -> ch)
        @props.onchange @props.scope, res

        if @state.last_move?
            if (r1 is r2 and @state.last_move[1] is 0) or
               (c1 is c2 and @state.last_move[0] is 0)
                @move_sel(@state.last_move[0], @state.last_move[1])

    view_to_data: (r,c) ->
        rc = Math.floor(@state.view_r/2)
        cc = Math.floor(@state.view_c/2)
        r = @state.view_r0 + r-rc
        c = @state.view_c0 + c-cc
        return [r,c]

    get_sel_box_view: ->
        r1 = @state.sel_A[0]
        r2 = @state.sel_B[0]
        if r1>r2 then [r1,r2]=[r2,r1]
        c1 = @state.sel_A[1]
        c2 = @state.sel_B[1]
        if c1>c2 then [c1,c2]=[c2,c1]
        return [r1,c1,r2,c2]

    get_sel_box_data: ->
        [r1,c1,r2,c2] = @get_sel_box_view()
        [r1,c1] = @view_to_data(r1,c1)
        [r2,c2] = @view_to_data(r2,c2)
        return [r1,c1,r2,c2]

    fill_data: (r1,c1, r2,c2, func) ->
        res = []
        for r,vr of @state.data_hash
            for c,vc of vr
                if not (r1 <= r and r <= r2 and c1 <= c and c <= c2)
                    res.push([r,c,vc])
        for r in [r1...r2+1]
            for c in [c1...c2+1]
                x = func(r,c)
                continue if x is ' '
                res.push([r,c,x])
        return res

    render: ->
        <div className='grid-table' ref='table'>
            <table><tbody>
            {
                for r in [0...@state.view_r]
                    <tr key={r}>
                    {
                        for c in [0...@state.view_c]
                            [r1,c1] = @view_to_data(r,c)
                            x = @get_data(r1,c1)
                            if x is ' '
                                color_fg = null
                                color_bg = null
                            else
                                color_fg = char_colors_fg[x]
                                color_bg = char_colors_bg[x]
                            <td key={c} style={
                                'backgroundColor':color_bg,
                                'color':color_fg }>
                            {x}
                            </td>
                    }
                    </tr>
            }
            </tbody></table>
            <div className='grid-sel' ref='sel-box' style={
                [r1,c1,r2,c2] = @get_sel_box_view()
                left:   c1 * grid_size
                top:    r1 * grid_size
                height: (r2-r1+1) * grid_size-3
                width:  (c2-c1+1) * grid_size-3
            }/>
        </div>

GridPage = React.createClass
    render: ->
        data = @props.data

        <div>
        {
            switch
                when data.length is 1
                    url_scope = utils.url_to_scope(document.location.pathname)
                    if not _.isEqual(url_scope, data[0].k)
                        document.location.pathname = utils.scope_to_url(data[0].k)
                    else
                        <SingleGridPage
                            scope={@props.data[0].k}
                            data={@props.data[0].v}
                            onchange={@props.onchange}/>
                when data.length > 1
                    data.map (X, K) =>
                        <div key={K} className='active-entry'>
                            <div className='ball'/>
                            <div className='entry-text'>
                                <widgets.Scope scope={X.k}/>
                            </div>
                        </div>
                when data.length is 0
                    if data.length is 0
                        <div className='no-results'>
                            no such parameters.
                        </div>
        }
        </div>

module.exports = GridPage