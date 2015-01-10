React = require('react')
utils = require('./utils')
_ = require('lodash')

Slider = React.createClass
    check_update: (evt) ->
        div = @refs.slider.getDOMNode()
        div_width = div.offsetWidth
        div_left = utils.ele_left(div)
        new_val = (evt.pageX - div_left) / div_width
        if new_val < 0 then new_val = 0
        else if new_val > 1 then new_val = 1
        @props.onchange new_val if @props.onchange?

    global_onmousemove: (evt) ->
        @check_update evt

    global_onmouseup: (evt) ->
        document.removeEventListener('mousemove', @global_onmousemove)
        document.removeEventListener('mouseup', @global_onmouseup)

    onmousedown: (evt) ->
        document.addEventListener('mousemove', @global_onmousemove)
        document.addEventListener('mouseup', @global_onmouseup)
        @check_update evt

    ontouchstart: (evt) ->
        document.addEventListener('touchmove', @global_ontouchmove)
        document.addEventListener('touchend', @global_ontouchend)
        @check_update evt.touches[0]
        evt.preventDefault()

    global_ontouchmove: (evt) ->
        @check_update evt.touches[0]
        evt.preventDefault()

    global_ontouchend: (evt) ->
        document.removeEventListener('touchmove', @global_ontouchmove)
        document.removeEventListener('touchend', @global_ontouchend)

    render: ->
        <div className='slider' ref='slider' onMouseDown={@onmousedown} onTouchStart={@ontouchstart}>
            <div className='base-line'/>
            <div className='pin' style={left: @props.val*100+'%'}/>
        </div>

Scope = React.createClass
    render: ->
        scope = @props.scope
        <div className='scope'>
        {
            scope.map (X, K) ->
                <span key={K}>
                    {
                        if K isnt 0
                            if _.isNumber(X)
                                <span className='spliter'>&nbsp;</span>
                            else
                                <span className='spliter'>&nbsp;.&nbsp;</span>
                    }
                    <span key={K}><a href={utils.scope_to_url(scope[0..K])}>
                    {
                        if _.isNumber(X) then '['+X+']' else X
                    }
                    </a></span>
                </span>
        }
        </div>

module.exports =
    Slider: Slider
    Scope: Scope
