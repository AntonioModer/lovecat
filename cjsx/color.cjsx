React = require('react')
widgets = require('./widgets')
_ = require('lodash')
utils = require('./utils')
TablePage = require('./table')
Color = require('color')

mono_font = '"Liberation Mono", "Nimbus Mono L", "FreeMono", "DejaVu Mono", "Bitstream Vera Mono", "Lucida Console", "Andale Mono", "Courier New", monospace'

main_color = '#ed5f9f'
secondary_color = '#edad5f'

selecter_orientation = (W, H) ->
    if W+120 < H then 'horizontal' else 'vertical'

table_position = (retina, W,H, L,R,T,B) ->
    if retina
        W *= 2; H *= 2
        L *= 2; R *= 2
        T *= 2; B *= 2
    [BX,BY] = [W-L-R, H-T-B]
    size = Math.min(BX, BY)
    if size % 2 == 0 then size -= 1
    return [ L+Math.floor((BX-size)/2), T+Math.floor((BY-size)/2)
             size, size ]

circle_table_position = (retina, W, H) ->
    table_position retina, W,H, 20,20,120,20

square_table_position = (retina, W, H) ->
    switch selecter_orientation(W, H)
        when 'horizontal'
            table_position retina, W,H, 30,30,130,95
        when 'vertical'
            table_position retina, W,H, 100,30,120,30

circle_data_position = (h, x, L, T, W, H) ->

circle_move_data = (h, x, x0,y0, x1,y1, L,T,W,H) ->


HSPage = React.createClass
    render: ->
        <TablePage
            data = {@props.data}
            onchange = {@props.onchange}
            table_position = { circle_table_position }
            data_to_screen = { ([h,s,v], L, T, W, H) ->
                circle_data_position(h,s, L,T,W,H)
            }
            move_data = { ([h,s,v], x0,y0, x1,y1, L,T,W,H) ->
                [h,s] = circle_move_data(h,s, x0,y0, x1,y1, L,T,W,H)
                return [h,s,v]
            }
            select_threshold = { (touch, retina) ->
                threshold = 5
                if touch then threshold = 20
                if retina then threshold *= 2
                return threshold
            }
            draw_data_point = { (ctx, retina, data, x,y, hover, selected) ->
            }
            draw_data_label = { (ctx, retina, data, x,y, hover, selected) =>
                ctx.fillStyle = '#555'
                label = utils.subscope_to_text(@props.scope, data.k)
                if retina
                    ctx.font = '18pt ' + mono_font
                    ctx.fillText(label, x+20, y-20)
                else
                    ctx.font = '9pt ' + mono_font
                    ctx.fillText(label, x+10, y-10)
            }
            draw_select_box = { (ctx, retina, L,T,W,H) ->
                ctx.strokeStyle = main_color
                ctx.fillStyle = main_color

                ctx.globalAlpha = 0.05
                ctx.fillRect(L,T,W,H)
                ctx.globalAlpha = 0.7

                if retina
                    ctx.lineWidth = 2
                    ctx.strokeRect(L,T,W,H)
                else
                    ctx.strokeRect(L+0.5,T+0.5,W,H)
            }
            draw_bg = { (ctx, retina, L,T,W,H) ->
                center_x = L+W/2
                center_y = T+H/2
                size = W

                ctx.beginPath()
                ctx.arc(center_x, center_y, W/2, 0, Math.PI * 2)
                ctx.clip()

                fixed_v = 100

                X = ctx.createImageData(size, size)
                console.assert X.width==size

                center = (size-1)/2

                return
                console.log size

                color = Color()
                for i in [0..size-1]
                    for j in [0..size-1]
                        idx = (i*size+j)*4

                        dist = Math.sqrt((i-center)*(i-center) + (j-center)*(j-center))
                        s = dist / center * 100

                        if i==center and j==center
                            h = 0
                        else
                            h = (Math.atan2(i-center, j-center) / Math.PI + 1) * 180

                        color = color.hsv(h, s, fixed_v)
                        X.data[idx]   = color.red()
                        X.data[idx+1] = color.green()
                        X.data[idx+2] = color.blue()
                        X.data[idx+3] = 255
                    console.log i

                ctx.putImageData(X, L+0.5, T+0.5)
            } />

SVPage = React.createClass
    render: ->
        <TablePage
            data = {@props.data}
            onchange = {@props.onchange}
            table_position = { square_table_position }
            data_to_screen = { ([h,s,v], L, T, W, H) ->
                circle_data_position(h,s, L,T,W,H)
            }
            move_data = { ([h,s,v], x0,y0, x1,y1, L,T,W,H) ->
                [h,s] = circle_move_data(h,s, x0,y0, x1,y1, L,T,W,H)
                return [h,s,v]
            }
            select_threshold = { (touch, retina) ->
                threshold = 5
                if touch then threshold = 20
                if retina then threshold *= 2
                return threshold
            }
            draw_data_point = { (ctx, retina, data, x,y, hover, selected) ->
            }
            draw_data_label = { (ctx, retina, data, x,y, hover, selected) =>
                ctx.fillStyle = '#555'
                label = utils.subscope_to_text(@props.scope, data.k)
                if retina
                    ctx.font = '18pt ' + mono_font
                    ctx.fillText(label, x+20, y-20)
                else
                    ctx.font = '9pt ' + mono_font
                    ctx.fillText(label, x+10, y-10)
            }
            draw_select_box = { (ctx, retina, L,T,W,H) ->
                ctx.strokeStyle = main_color
                ctx.fillStyle = main_color

                ctx.globalAlpha = 0.05
                ctx.fillRect(L,T,W,H)
                ctx.globalAlpha = 0.7

                if retina
                    ctx.lineWidth = 2
                    ctx.strokeRect(L,T,W,H)
                else
                    ctx.strokeRect(L+0.5,T+0.5,W,H)
            }
            draw_bg = { (ctx, retina, L,T,W,H) ->
                ctx.strokeStyle = '#bbb'

                if retina
                    ctx.lineWidth = 2
                    ctx.strokeRect(L,T,W,H)
                else
                    ctx.strokeRect(L+0.5,T+0.5,W-1,H-1)
            } />

ColorPage = React.createClass
    getInitialState: ->
        mode: 'HS'
        mode_selecter_orientation: null

    onmodechange: (mode) ->
        @setState mode: mode

    onresize: (evt) ->
        W = document.documentElement.clientWidth
        H = document.documentElement.clientHeight

        console.log W, H

        orientation = selecter_orientation(W, H)
        if orientation isnt @state.mode_selecter_orientation
            @setState
                mode_selecter_orientation: orientation

    componentWillMount: ->
        do @onresize

    componentDidMount: ->
        window.addEventListener('resize', @onresize)

    componentWillUnmount: ->
        window.removeEventListener('resize', @onresize)

    render: ->
        <div>
            <div className='color-mode'>
                <widgets.BoxSelecter
                    choices={['HS', 'HV', 'SV']}
                    active={@state.mode}
                    onchange={@onmodechange}
                    orientation={@state.mode_selecter_orientation} />
            </div>
        {
            switch @state.mode
                when 'HS'
                    <HSPage data={@props.data}
                        onchange={@props.onchange} scope={@props.scope}/>
                when 'HV'
                    <HSPage data={@props.data}
                        onchange={@props.onchange} scope={@props.scope}/>
                when 'SV'
                    <SVPage data={@props.data}
                        onchange={@props.onchange} scope={@props.scope}/>
        }
        </div>

module.exports = ColorPage