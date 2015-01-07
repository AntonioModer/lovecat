React = require('react')
domready = require('domready')
utils = require('./utils')

Test = React.createClass
    render: ->
        <div className='abc'>
            hello!
        </div>

ele_left = (ele) ->
    ans = 0
    while ele?
        ans += ele.offsetLeft
        ele = ele.offsetParent
    return ans

Slider = React.createClass
    onclick: (evt) ->
        div = @refs.slider.getDOMNode()
        div_width = div.offsetWidth
        div_left = ele_left(div)
        new_val = (evt.pageX - div_left) / div_width
        @props.onchange new_val if @props.onchange?

    render: ->
        <div className='slider' onClick={@onclick} onMouseMove={@onclick} ref='slider'>
            <div className='base-line'/>
            <div className='pin' style={left: @props.val*100+'%'}/>
        </div>

ListSlider = React.createClass
    render: ->
        <div>
            <Slider val={0.5} onchange={(val) ->
                console.log(val)
                utils.send_update ['number', 'ClassA', 'ClassB', 'size'], ''+val}/>
            <Slider val={0.5} onchange={(val) ->
                console.log(val)
                utils.send_update ['number', 'ClassA', 'ClassB', 'x'], ''+val}/>
            <Slider val={0.5} onchange={(val) ->
                console.log(val)
                utils.send_update ['number', 'ClassA', 'ClassB', 'y'], ''+val}/>
            <Slider val={0}/>
            <Slider val={0.2}/>
            <Slider val={0.3}/>
            <Slider val={1}/>
        </div>

domready ->
    utils.fetch_view ['number']

    utils.send_update ['number', 'ClassA', 'ClassB', 'x'], '0.9'

    React.render(<ListSlider/>, document.getElementById('page'))
