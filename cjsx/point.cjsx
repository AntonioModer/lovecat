React = require('react')
widgets = require('./widgets')
_ = require('lodash')
utils = require('./utils')

is_retina = utils.is_retina
is_touch_device = utils.is_touch_device

mono_font = '"Liberation Mono", "Nimbus Mono L", "FreeMono", "DejaVu Mono", "Bitstream Vera Mono", "Lucida Console", "Andale Mono", "Courier New", monospace'

main_color = '#ed5f9f'
main_color_lighten = '#fff8ff'
secondary_color = '#edad5f'
secondary_color_lighten = '#ffe092'
label_font = mono_font

PointPage = React.createClass
    getInitialState: ->
        focus: null
        focus_touch: null

        selected: null
        selected_box: null
        select_shift: null
        select_box_A: null
        select_box_B: null

        table_left: null
        table_top: null
        table_width: null
        table_height: null

    place_canvas: ->
        view_width = document.documentElement.clientWidth
        view_height = document.documentElement.clientHeight
        @refs.canvas.getDOMNode().style.height = view_height + 'px'

        if is_retina()
            @refs.canvas.getDOMNode().height = view_height * 2
            @refs.canvas.getDOMNode().width = view_width * 2

            size = Math.min(view_width*2-120, view_height*2-360)

            @setState
                table_left: Math.floor((view_width*2-size)/2)
                table_top: 300
                table_width: size
                table_height: size
        else
            @refs.canvas.getDOMNode().height = view_height
            @refs.canvas.getDOMNode().width = view_width

            size = Math.min(view_width-60, view_height-180)
            if size % 2 == 0 then size -= 1

            @setState
                table_left: Math.floor((view_width-size)/2)
                table_top: 150
                table_width: size
                table_height: size

    redraw: ->
        canvas = @refs.canvas.getDOMNode()
        ctx = canvas.getContext('2d')
        ctx.clearRect(0, 0, canvas.width, canvas.height)

        do @draw_select_box
        do @draw_bg
        do @draw_data

    draw_data: ->
        canvas = @refs.canvas.getDOMNode()
        ctx = canvas.getContext('2d')
        ctx.save()

        now_selected = @get_selected()

        for data in @props.data
            [x, y] = data.v
            x = @state.table_left + @state.table_width * (1+x)/2
            y = @state.table_top + @state.table_height * (1-y)/2

            circle_r = 4
            circle_r2 = 7
            if @state.focus_touch then circle_r2 = 20
            if is_retina()
                circle_r *= 2
                circle_r2 *= 2
                ctx.lineWidth = 2

            if _.contains(now_selected, data.k)
                ctx.fillStyle = secondary_color
            else
                ctx.fillStyle = main_color

            ctx.beginPath()
            ctx.arc(x, y, circle_r, 0, Math.PI*2)
            ctx.fill()

            if _.isEqual @state.focus, data.k
                ctx.strokeStyle = ctx.fillStyle
                ctx.beginPath()
                ctx.arc(x, y, circle_r2, 0, Math.PI*2)
                ctx.stroke()

            ctx.fillStyle = '#555'
            label = utils.subscope_to_text(@props.scope, data.k)
            if is_retina()
                ctx.font = '18pt ' + label_font
                ctx.fillText(label, x+20, y-20)
            else
                ctx.font = '9pt ' + label_font
                ctx.fillText(label, x+10, y-10)

        ctx.restore()

    draw_bg: ->
        canvas = @refs.canvas.getDOMNode()
        ctx = canvas.getContext('2d')
        ctx.save()

        ctx.strokeStyle = '#bbb'

        if is_retina()
            ctx.lineWidth = 2

            ctx.strokeRect(@state.table_left, @state.table_top, @state.table_width, @state.table_height)
        else
            ctx.strokeRect(@state.table_left+0.5, @state.table_top+0.5, @state.table_width-1, @state.table_height-1)

        center_x = @state.table_left + @state.table_width/2
        center_y = @state.table_top + @state.table_height/2

        ctx.strokeStyle = '#ddd'
        ctx.setLineDash [6, 5]
        ctx.beginPath()
        ctx.moveTo(center_x, center_y)
        ctx.lineTo(center_x, @state.table_top + @state.table_height)
        ctx.stroke()

        ctx.beginPath()
        ctx.moveTo(center_x, center_y)
        ctx.lineTo(center_x, @state.table_top)
        ctx.stroke()

        ctx.beginPath()
        ctx.moveTo(center_x, center_y)
        ctx.lineTo(@state.table_left, center_y)
        ctx.stroke()

        ctx.beginPath()
        ctx.moveTo(center_x, center_y)
        ctx.lineTo(@state.table_left + @state.table_width, center_y)
        ctx.stroke()

        ctx.restore()

    get_select_box: ->
        [x1, y1] = @state.select_box_A
        [x2, y2] = @state.select_box_B

        if x1 > x2 then [x1, x2] = [x2, x1]
        if y1 > y2 then [y1, y2] = [y2, y1]
        return [x1, y1, x2, y2]

    get_selected: ->
        ori_selected = @state.selected or []
        new_selected = @state.selected_box or []
        if @state.select_shift is null
            res = ori_selected
        else if @state.select_shift
            res = _.xor(ori_selected, new_selected)
        else
            res = new_selected
        if _.isEmpty(res) then null else res

    draw_select_box: ->
        return if not @state.select_box_A?

        canvas = @refs.canvas.getDOMNode()
        ctx = canvas.getContext('2d')
        ctx.save()

        ctx.strokeStyle = main_color
        ctx.fillStyle = main_color_lighten

        [x1, y1, x2, y2] = @get_select_box()
        ctx.fillRect(x1, y1, x2-x1, y2-y1)

        if is_retina()
            ctx.lineWidth = 2
            ctx.strokeRect(x1, y1, x2-x1, y2-y1)
        else
            ctx.strokeRect(x1+0.5, y1+0.5, x2-x1, y2-y1)

        ctx.restore()

    componentWillMount: ->
        @moving_x0 = null
        @moving_y0 = null
        @moving_points0 = null

    componentDidMount: ->
        do @place_canvas
        window.addEventListener('resize', @place_canvas)
        window.addEventListener('mousemove', @onmousemove)
        window.addEventListener('mousedown', @onmousedown)
        window.addEventListener('mouseup', @onmouseup)
        window.addEventListener('touchmove', @ontouchmove)
        window.addEventListener('touchstart', @ontouchstart)
        window.addEventListener('touchend', @ontouchend)

    componentDidUpdate: ->
        do @redraw

    componentWillUnmount: ->
        window.removeEventListener('resize', @place_canvas)
        window.removeEventListener('mousemove', @onmousemove)
        window.removeEventListener('mousedown', @onmousedown)
        window.removeEventListener('mouseup', @onmouseup)
        window.removeEventListener('touchmove', @ontouchmove)
        window.removeEventListener('touchstart', @ontouchstart)
        window.removeEventListener('touchend', @ontouchend)

    ontouchmove: (evt) ->
        alpha = if is_retina() then 2 else 1
        proxy_evt =
            pageX: evt.touches[0].pageX * alpha
            pageY: evt.touches[0].pageY * alpha
            clientX: evt.touches[0].clientX * alpha
            clientY: evt.touches[0].clientY * alpha
        @onmousemove(proxy_evt, true)
        evt.preventDefault()

    ontouchstart: (evt) ->
        alpha = if is_retina() then 2 else 1
        proxy_evt =
            pageX: evt.touches[0].pageX * alpha
            pageY: evt.touches[0].pageY * alpha
            clientX: evt.touches[0].clientX * alpha
            clientY: evt.touches[0].clientY * alpha
        @onmousedown(proxy_evt, true)

    ontouchend: (evt) ->
        @onmouseup({}, true)
        if @state.focus isnt null
            @setState focus: null

    onmousedown: (evt, touch) ->
        x = evt.pageX - @state.table_left
        y = evt.pageY - @state.table_top
        @update_focus(evt, touch)

        if not @state.focus?
            @setState
                select_box_A: [evt.pageX, evt.pageY]
                select_box_B: [evt.pageX, evt.pageY]
                select_shift: evt.shiftKey
                selected_box: []
        else if not _.isEmpty(@state.selected) and not _.contains(@state.selected, @state.focus)
            @setState selected: null
        else
            @moving_x0 = evt.pageX
            @moving_y0 = evt.pageY

            moving = [@state.focus]
            moving = @state.selected if @state.selected?
            @moving_points0 = []
            for k in moving
                [mx, my] = _.find(@props.data, (x) -> _.isEqual(x.k, k)).v
                @moving_points0.push({k:k, v:[mx,my]})

    onmouseup: (evt, touch) ->
        if @state.select_box_B?
            selected = @get_selected()
            @setState
                select_box_A: null
                select_box_B: null
                selected_box: null
                select_shift: null
                selected: selected
        else if @moving_x0?
            @moving_x0 = null
            @moving_y0 = null
            @moving_points0 = null

    onmousemove: (evt, touch) ->
        if @state.select_box_B?
            @setState select_box_B: [evt.clientX, evt.clientY]

            [x1,y1, x2,y2] = @get_select_box()
            x1 -= @state.table_left
            x2 -= @state.table_left
            y1 -= @state.table_top
            y2 -= @state.table_top

            size = @state.table_width

            selected = []
            for point in @props.data
                [vx, vy] = point.v
                vx = size*(vx+1)/2
                vy = size*(1-vy)/2

                if x1 <= vx and vx <= x2 and
                   y1 <= vy and vy <= y2
                    selected.push(point.k)

            @setState selected_box: selected
        else if @moving_x0?
            dx = evt.clientX - @moving_x0
            dy = evt.clientY - @moving_y0
            size = @state.table_width
            dx /= size/2
            dy /= -size/2

            for point in @moving_points0
                [mx, my] = point.v
                mx += dx
                my += dy
                if mx < -1 then mx = -1
                if mx > 1 then mx = 1
                if my < -1 then my = -1
                if my > 1 then my = 1
                @props.onchange point.k, [mx, my]
        else
            @update_focus(evt)

    update_focus: (evt, touch) ->
        x = evt.clientX - @state.table_left
        y = evt.clientY - @state.table_top
        focus = null
        size = @state.table_width

        threshold = 5
        if touch then threshold = 20
        if is_retina() then threshold *= 2

        for m in @props.data
            [vx, vy] = m.v
            vx = size*(vx+1)/2
            vy = size*(1-vy)/2

            if Math.abs(vx - x) < threshold and
               Math.abs(vy - y) < threshold
                focus = m.k
                break

        if focus isnt @state.focus
            @setState
                focus: focus
                focus_touch: touch

    render: ->
        <canvas className='canvas' ref='canvas'/>

module.exports = PointPage