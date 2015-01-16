React = require('react')
widgets = require('./widgets')
_ = require('lodash')
utils = require('./utils')
TablePage = require('./table')
Color = require('color')
webgl = require('./webgl')

mono_font = '"Liberation Mono", "Nimbus Mono L", "FreeMono", "DejaVu Mono", "Bitstream Vera Mono", "Lucida Console", "Andale Mono", "Courier New", monospace'

main_color = '#ed5f9f'
secondary_color = '#edad5f'

shader_hs = """
precision highp float;
uniform vec2 center;
uniform vec2 radius;
uniform float fixed_v;

#define PI 3.1415926535897932384626433832795

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float in_circle(float x, float y) {
    float dx = x - center.x;
    float dy = y - center.y;
    float sqr_dist = dx*dx + dy*dy;
    float c = step(sqr_dist, radius.y);
    return c;
}

float in_circle_multi_sample() {
    float c  = 1.0/4.0;
    float c2 = c+c;
    float x = gl_FragCoord.x - c/2.0;
    float y = gl_FragCoord.y - c/2.0;
    float res = 0.0;
    res += in_circle(x-c, y-c);
    res += in_circle(x-c, y);
    res += in_circle(x-c, y+c);
    res += in_circle(x-c, y+c2);
    res += in_circle(x,   y-c);
    res += in_circle(x,   y);
    res += in_circle(x,   y+c);
    res += in_circle(x,   y+c2);
    res += in_circle(x+c, y-c);
    res += in_circle(x+c, y);
    res += in_circle(x+c, y+c);
    res += in_circle(x+c, y+c2);
    res += in_circle(x+c2, y-c);
    res += in_circle(x+c2, y);
    res += in_circle(x+c2, y+c);
    res += in_circle(x+c2, y+c2);
    return res/16.0;
}

void main(void) {
    vec2 pos = gl_FragCoord.xy;
    float dx = pos.x - center.x;
    float dy = pos.y - center.y;
    float sqr_dist = dx*dx + dy*dy;

    float alpha = in_circle_multi_sample();
    float hue = (-atan(dy, dx) / PI + 1.0)/2.0;
    hue = mod(hue-0.25, 1.0);
    float sat = sqrt(sqr_dist) / radius.x;

    vec3 rgb = hsv2rgb(vec3(hue,sat,fixed_v));

    gl_FragColor = vec4(rgb, alpha);
}
"""

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
                ctx.strokeStyle = '#fff'
                ctx.fillStyle = '#fff'

                ctx.globalAlpha = 0.05
                ctx.fillRect(L,T,W,H)
                ctx.globalAlpha = 0.7

                if retina
                    ctx.lineWidth = 2
                    ctx.strokeRect(L,T,W,H)
                else
                    ctx.strokeRect(L+0.5,T+0.5,W,H)
            }
            bg_need_redraw = { (W,H, canvas, state) ->
                return if W is canvas.width and H is canvas.height
                'webgl'
            }
            draw_bg = { (gl, retina, L,T,W,H) ->
                canvas = gl.canvas
                CH = canvas.height
                center_x = L+W/2
                center_y = T+H/2

                if not canvas.shader?
                    canvas.shader = webgl.compile_shader gl, shader_hs
                webgl.draw_rect gl, L,CH-(T+H),H,W, canvas.shader,
                    center: [center_x, CH-center_y]
                    radius: [W/2, (W/2)*(W/2)]
                    fixed_v: 0.8
            } />

HVPage = React.createClass
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
                ctx.strokeStyle = '#fff'
                ctx.fillStyle = '#fff'

                ctx.globalAlpha = 0.05
                ctx.fillRect(L,T,W,H)
                ctx.globalAlpha = 0.7

                if retina
                    ctx.lineWidth = 2
                    ctx.strokeRect(L,T,W,H)
                else
                    ctx.strokeRect(L+0.5,T+0.5,W,H)
            }
            bg_need_redraw = { (W,H, canvas, state) ->
                return if W is canvas.width and H is canvas.height
                'webgl'
            }
            draw_bg = { (gl, retina, L,T,W,H) ->
                canvas = gl.canvas
                CH = canvas.height
                center_x = L+W/2
                center_y = T+H/2

                if not canvas.shader?
                    canvas.shader = webgl.compile_shader gl, shader_hs
                webgl.draw_rect gl, L,CH-(T+H),H,W, canvas.shader,
                    center: [center_x, CH-center_y]
                    radius: [W/2, (W/2)*(W/2)]
                    fixed_v: 1
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
                    <HVPage data={@props.data}
                        onchange={@props.onchange} scope={@props.scope}/>
                when 'SV'
                    <SVPage data={@props.data}
                        onchange={@props.onchange} scope={@props.scope}/>
        }
        </div>

module.exports = ColorPage