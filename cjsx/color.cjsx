React = require('react')
widgets = require('./widgets')
_ = require('lodash')
utils = require('./utils')
TablePage = require('./table')
Color = require('color')
webgl = require('./webgl')

mono_font = '"Liberation Mono", "Nimbus Mono L", "FreeMono", "DejaVu Mono", "Bitstream Vera Mono", "Lucida Console", "Andale Mono", "Courier New", monospace'

main_color = '#c666d9'
secondary_color = '#d96679'

shader_hx = """
precision highp float;
uniform vec2 center;
uniform vec2 radius;

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
"""

shader_hs = shader_hx + """
uniform float fixed_v;

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

shader_hv = shader_hx + """
uniform float fixed_s;

void main(void) {
    vec2 pos = gl_FragCoord.xy;
    float dx = pos.x - center.x;
    float dy = pos.y - center.y;
    float sqr_dist = dx*dx + dy*dy;

    float alpha = in_circle_multi_sample();
    float hue = (-atan(dy, dx) / PI + 1.0)/2.0;
    hue = mod(hue-0.25, 1.0);
    float val = sqrt(sqr_dist) / radius.x;

    vec3 rgb = hsv2rgb(vec3(hue,fixed_s,val));

    gl_FragColor = vec4(rgb, alpha);
}
"""

shader_sv = """
precision highp float;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

uniform float fixed_h;
uniform vec2 lower;
uniform float size;

void main(void) {
    vec2 pos = gl_FragCoord.xy;
    float dx = pos.x - lower.x;
    float dy = pos.y - lower.y;

    float hue = dx / size;
    float val = dy / size;

    vec3 rgb = hsv2rgb(vec3(fixed_h,hue,val));
    gl_FragColor = vec4(rgb, 1);
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
    h = (h/180-0.5) * Math.PI
    r = W/2
    r *= x/100
    [center_x,center_y] = [L+W/2, T+H/2]
    return [center_x + Math.cos(h)*r, center_y + Math.sin(h)*r]

dist = (dx, dy) ->
    Math.sqrt(dx*dx+dy*dy)

circle_move_data = (h, x, x0,y0, x1,y1, L,T,W,H) ->
    [center_x, center_y] = [L+W/2, T+H/2]

    if ((Math.abs(center_x - x0) < 1e-3 and Math.abs(center_y - y0) < 1e-3) or
       (Math.abs(center_x - x1) < 1e-3 and Math.abs(center_y - y1) < 1e-3))
        delta_h = 0
    else
        theta_0 = Math.atan2(y0-center_y, x0-center_x)
        theta_1 = Math.atan2(y1-center_y, x1-center_x)
        delta_h = (theta_1-theta_0) / Math.PI * 180
    h = ((h+delta_h)%360+360)%360

    r = W/2
    dist0 = dist(center_x-x0, center_y-y0) / r
    dist1 = dist(center_x-x1, center_y-y1) / r
    x += (dist1-dist0) * 100
    if x > 100 then x = 100
    else if x < 0 then x = 0

    return [h,x]

data_color = (data) ->
    color = Color().hsv(data.v[0], data.v[1], data.v[2])
    return color.rgbString()

draw_data_point = (ctx, retina, data, x,y, hover, selected) ->
    RE = if retina then 2 else 1

    fill_circle = (x,y,r, color) ->
        ctx.beginPath()
        ctx.arc(x,y,r*RE, 0, Math.PI*2)
        ctx.fillStyle = color
        ctx.fill()

    stroke_circle = (x,y,r, color, w) ->
        ctx.beginPath()
        ctx.arc(x,y,r*RE, 0, Math.PI*2)
        ctx.strokeStyle = color
        ctx.lineWidth = w*RE
        ctx.stroke()

    fill_circle(x,y,10, '#fff')
    fill_circle(x,y,8, data_color(data))
    if selected
        stroke_circle(x,y,14, '#fff', 2)

    if hover?
        ctx.fillStyle = data_color(data)
        ctx.globalAlpha = 1
        ctx.strokeStyle = '#fff'
        ctx.lineWidth = RE
        x2 = Math.round(x)
        y2 = Math.round(y)
        if retina
            ctx.fillRect   x2-60,y2-140,120,120
            ctx.strokeRect x2-60,y2-140,120,120
        else
            ctx.strokeRect x2-30+0.5,y2-90+0.5,60,60
            ctx.fillRect   x2-30+0.5,y2-90+0.5,60,60

draw_data_label = (ctx, retina, data, x,y, hover, selected) ->
    label = utils.subscope_to_text(@props.scope, data.k)
    if retina
        ctx.font = '18pt ' + mono_font
    else
        ctx.font = '9pt ' + mono_font

    TW = ctx.measureText(label).width
    RE = if retina then 2 else 1

    ctx.fillStyle = '#fff'
    ctx.globalAlpha = 0.3
    ctx.fillRect x+10*RE, y-22*RE, TW+3*RE, 16*RE
    ctx.fillStyle = '#333'
    ctx.globalAlpha = 1
    ctx.fillText(label, x+10*RE, y-10*RE)

draw_select_box = (ctx, retina, L,T,W,H) ->
    ctx.strokeStyle = '#fff'
    ctx.fillStyle = '#fff'

    ctx.globalAlpha = 0.2
    ctx.fillRect(L,T,W,H)
    ctx.globalAlpha = 0.9

    if retina
        ctx.lineWidth = 2
        ctx.strokeRect(L,T,W,H)
    else
        ctx.strokeRect(L+0.5,T+0.5,W,H)

select_threshold = (touch, retina) ->
    threshold = 9
    if touch then threshold = 20
    if retina then threshold *= 2
    return threshold

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
            select_threshold = { select_threshold }
            draw_data_point = { draw_data_point }
            draw_data_label = { draw_data_label.bind(@) }
            draw_select_box = { draw_select_box }
            bg_need_redraw = { (W,H, canvas, hover_data) ->
                fixed_v = 1.0
                if hover_data? then fixed_v = hover_data.v[2] / 100
                # alert 'check redraw' + W + ',' + canvas.width
                return if (W is canvas.width and H is canvas.height and
                           canvas.fixed_v is fixed_v)
                canvas.fixed_v = fixed_v
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
                    fixed_v: canvas.fixed_v
            } />

HVPage = React.createClass
    render: ->
        <TablePage
            data = {@props.data}
            onchange = {@props.onchange}
            table_position = { circle_table_position }
            data_to_screen = { ([h,s,v], L, T, W, H) ->
                circle_data_position(h,v, L,T,W,H)
            }
            move_data = { ([h,s,v], x0,y0, x1,y1, L,T,W,H) ->
                [h,v] = circle_move_data(h,v, x0,y0, x1,y1, L,T,W,H)
                return [h,s,v]
            }
            select_threshold = { select_threshold }
            draw_data_point = { draw_data_point }
            draw_data_label = { draw_data_label.bind(@) }
            draw_select_box = { draw_select_box }
            bg_need_redraw = { (W,H, canvas, hover_data) ->
                fixed_s = 1.0
                if hover_data? then fixed_s = hover_data.v[1] / 100
                return if (W is canvas.width and H is canvas.height and
                           canvas.fixed_s is fixed_s)
                canvas.fixed_s = fixed_s
                'webgl'
            }
            draw_bg = { (gl, retina, L,T,W,H) ->
                canvas = gl.canvas
                CH = canvas.height
                center_x = L+W/2
                center_y = T+H/2

                if not canvas.shader?
                    canvas.shader = webgl.compile_shader gl, shader_hv
                webgl.draw_rect gl, L,CH-(T+H),H,W, canvas.shader,
                    center: [center_x, CH-center_y]
                    radius: [W/2, (W/2)*(W/2)]
                    fixed_s: canvas.fixed_s
            } />

SVPage = React.createClass
    render: ->
        <TablePage
            data = {@props.data}
            onchange = {@props.onchange}
            table_position = { square_table_position }
            data_to_screen = { ([h,s,v], L, T, W, H) ->
                x = L+s/100 * W
                y = T+H - v/100*H
                return [x,y]
            }
            move_data = { ([h,s,v], x0,y0, x1,y1, L,T,W,H) ->
                dx = (x1-x0)/W * 100
                dy = -(y1-y0)/H * 100
                s += dx
                v += dy
                if s < 0 then s = 0
                if s > 100 then s = 100
                if v < 0 then v = 0
                if v > 100 then v = 100
                return [h,s,v]
            }
            select_threshold = { select_threshold }
            draw_data_point = { draw_data_point }
            draw_data_label = { draw_data_label.bind(@) }
            draw_select_box = { draw_select_box }
            bg_need_redraw = { (W,H, canvas, hover_data) ->
                fixed_h = 0
                if hover_data? then fixed_h = hover_data.v[0] / 360
                return if (W is canvas.width and H is canvas.height and
                           (canvas.fixed_h is fixed_h or not hover_data?))
                canvas.fixed_h = fixed_h
                'webgl'
            }
            draw_bg = { (gl, retina, L,T,W,H) ->
                canvas = gl.canvas
                CH = canvas.height

                if not canvas.shader?
                    canvas.shader = webgl.compile_shader gl, shader_sv
                webgl.draw_rect gl, L,CH-(T+H),H,W, canvas.shader,
                    lower: [L, CH-(T+H)]
                    size: W
                    fixed_h: canvas.fixed_h
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
        window.addEventListener('keydown', @onkeydown)

    componentWillUnmount: ->
        window.removeEventListener('resize', @onresize)
        window.removeEventListener('keydown', @onkeydown)

    onkeydown: (evt) ->
        return if evt.target.nodeName is 'INPUT'
        if evt.key is '1' or evt.keyIdentifier is 'U+0031'
            @setState mode: 'HS'
            evt.preventDefault()
        if evt.key is '2' or evt.keyIdentifier is 'U+0032'
            @setState mode: 'HV'
            evt.preventDefault()
        if evt.key is '3' or evt.keyIdentifier is 'U+0033'
            @setState mode: 'SV'
            evt.preventDefault()

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