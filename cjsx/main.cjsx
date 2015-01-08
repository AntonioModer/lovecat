React = require('react')
domready = require('domready')
utils = require('./utils')
_ = require('lodash')
NumberPage = require('./number')

Test = React.createClass
    render: ->
        <div className='abc'>
            hello!
        </div>

NavBar = React.createClass
    scope_entry: ->
        if not @props.scope?
            'active'
        else
            @props.scope[0]

    entry: (x) ->
        cx = 'navitem'
        if x is @scope_entry()
            cx += ' active'
        <div className={cx}>{x}</div>

    render: ->
        <div className='navbar'>
            <div className='brand'>lovecat</div>&nbsp;

            { @entry('active') }
            { @entry('number') }
            { @entry('point') }
            { @entry('color') }
            { @entry('grid') }
        </div>

DataPage = React.createClass
    getInitialState: ->
        connected: false
        data_version: null
        data: []

    onstatus_ok: (res) ->
        ver = res.data_version
        if not ver?
            do onstatus_err
            return
        if not @state.connected
            utils.fetch_view @props.scope, (data) =>
                @setState
                    connected: true
                    data_version: ver
                    data: data
            return
        if ver isnt @state.data_version
            utils.fetch_view @props.scope, (data) =>
                @setState
                    data_version: ver
                    data: data
            return

    onstatus_err: ->
        @setState connected:false

    check_status: ->
        utils.fetch_status ((x) => @onstatus_ok x), (=> do @onstatus_err)

    format_value: (kind, v) ->
        switch kind
            when 'number' then String(v)

    onchange: (k, v) ->
        utils.send_update k, @format_value(k[0], v)
        for x in @state.data
            if _.isEqual(x.k, k)
                x.v = v
                break
        do @forceUpdate

    componentDidMount: ->
        do @check_status
        @timer = setInterval (=> do @check_status), 500

    componentWillUnmount: ->
        clearInterval @timer

    render: ->
        <div>
            <NavBar scope={@props.scope}/>
            <div className='page-content'>
            {
                if not @state.connected
                    <div className='disconnected'>Disconnected.</div>
                else
                    switch @props.scope[0]
                        when 'number'
                            <NumberPage data={@state.data} onchange={@onchange}/>
            }
            </div>
        </div>

TopPage = React.createClass
    scope_entry: ->
        if not @props.scope?
            'active'
        else
            @props.scope[0]

    render: ->
        <div className={'theme-'+@scope_entry()}>
            <DataPage scope={@props.scope}/>
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
    React.initializeTouchEvents(true)
    React.render(<TopPage scope={['number']}/>, document.getElementById('page'))
