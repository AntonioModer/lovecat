React = require('react')
widgets = require('./widgets')
_ = require('lodash')
utils = require('./utils')

is_retina = utils.is_retina

TablePage = React.createClass
    getInitialState: ->
        hover: null
        hover_touch: null

        selected: null
        selected_in_box: null
        select_shift: null
        select_box_A: null
        select_box_B: null

        table_left: null
        table_top: null
        table_width: null
        table_height: null

        label_show: true

    place_canvas: ->
        view_width = document.documentElement.clientWidth
        view_height = document.documentElement.clientHeight
        @refs.canvas.getDOMNode().style.height = view_height + 'px'

        if is_retina()
            @refs.canvas.getDOMNode().height = view_height * 2
            @refs.canvas.getDOMNode().width = view_width * 2
        else
            @refs.canvas.getDOMNode().height = view_height
            @refs.canvas.getDOMNode().width = view_width

        [L,T,W,H] = @props.table_position(
            is_retina(),
            view_width, view_height)

        @setState
            table_left:   L
            table_top:    T
            table_width:  W
            table_height: H

    redraw: ->
        canvas = @refs.canvas.getDOMNode()
        ctx = canvas.getContext('2d')
        ctx.clearRect(0, 0, canvas.width, canvas.height)

        do @draw_bg
        do @draw_data
        do @draw_select_box

    data_to_screen: (data) ->
        return @props.data_to_screen(
            data.v,
            @state.table_left, @state.table_top,
            @state.table_width, @state.table_height
        )

    draw_data: ->
        canvas = @refs.canvas.getDOMNode()
        ctx = canvas.getContext('2d')

        now_selected = @get_selected()

        for data in @props.data
            [x, y] = @data_to_screen(data)

            hover = null
            if _.isEqual @state.hover, data.k
                if @state.hover_touch
                    hover = 'touch'
                else
                    hover = 'mouse'

            selected = _.contains(now_selected, data.k)

            ctx.save()
            @props.draw_data_point(
                ctx,
                is_retina(),
                data,
                x, y,
                hover,
                selected,
                @state
            )
            ctx.restore()

            if @state.label_show
                ctx.save()
                @props.draw_data_label(
                    ctx,
                    is_retina(),
                    data,
                    x, y,
                    hover,
                    selected,
                    @state
                )
                ctx.restore()

    draw_bg: ->
        canvas = @refs.canvas.getDOMNode()
        ctx = canvas.getContext('2d')
        ctx.save()

        if @props.draw_bg?
            @props.draw_bg(ctx, is_retina(),
                @state.table_left, @state.table_top,
                @state.table_width, @state.table_height,
                @state)

        ctx.restore()

    draw_select_box: ->
        return if not @state.select_box_A?

        canvas = @refs.canvas.getDOMNode()
        ctx = canvas.getContext('2d')
        ctx.save()

        [x1,y1,x2,y2] = @get_select_box()

        if @props.draw_select_box?
            @props.draw_select_box(ctx, is_retina(),
                x1, y1,
                x2-x1, y2-y1,
                @state)

        ctx.restore()

    get_select_box: ->
        [x1, y1] = @state.select_box_A
        [x2, y2] = @state.select_box_B

        if x1 > x2 then [x1, x2] = [x2, x1]
        if y1 > y2 then [y1, y2] = [y2, y1]
        return [x1, y1, x2, y2]

    get_selected: ->
        ori_selected = @state.selected or []
        new_selected = @state.selected_in_box or []
        if @state.select_shift is null
            res = ori_selected
        else if @state.select_shift
            res = _.xor(ori_selected, new_selected)
        else
            res = new_selected
        if _.isEmpty(res) then null else res

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
        window.addEventListener('keydown', @onkeydown)

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
        window.removeEventListener('keydown', @onkeydown)

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
        if @state.hover isnt null
            @setState hover: null

    onmousedown: (evt, touch) ->
        @update_hover(evt, touch)

        if not @state.hover?
            @setState
                select_box_A: [evt.pageX, evt.pageY]
                select_box_B: [evt.pageX, evt.pageY]
                select_shift: evt.shiftKey
                selected_in_box: []
        else if not _.isEmpty(@state.selected) and not _.contains(@state.selected, @state.hover)
            @setState selected: null
        else
            @moving_x0 = evt.pageX
            @moving_y0 = evt.pageY

            moving = [@state.hover]
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
                selected_in_box: null
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

            selected = []
            for point in @props.data
                [vx, vy] = @data_to_screen(point)
                if x1 <= vx and vx <= x2 and
                   y1 <= vy and vy <= y2
                    selected.push(point.k)

            @setState selected_in_box: selected
        else if @moving_x0?
            for point in @moving_points0
                [mx, my] = @props.move_data(point.v,
                    @moving_x0, @moving_y0,
                    evt.clientX, evt.clientY,
                    @state)
                @props.onchange point.k, [mx, my]
        else
            @update_hover(evt)

    update_hover: (evt, touch) ->
        x = evt.clientX
        y = evt.clientY
        hover = null

        threshold = @props.select_threshold(touch, is_retina())

        for m in @props.data
            [vx, vy] = @data_to_screen(m)

            if Math.abs(vx - x) < threshold and
               Math.abs(vy - y) < threshold
                hover = m.k
                break

        if hover isnt @state.hover
            @setState
                hover: hover
                hover_touch: touch

    onkeydown: (evt) ->
        return if evt.target.nodeName is 'INPUT'
        if evt.key is 't' or evt.keyIdentifier is 'U+0054'
            @setState
                label_show: not @state.label_show
            evt.preventDefault()

    render: ->
        <canvas className='canvas' ref='canvas'/>

module.exports = TablePage