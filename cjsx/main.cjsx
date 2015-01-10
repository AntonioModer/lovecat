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
    entry: (x) ->
        kind = @props.activeKind
        cx = 'navitem'
        cx += ' active' if x is kind
        if x is 'active'
            href = '/'
        else
            href = '/' + x
        <div className={cx}>
            <a href={href}>
                <span className='navitem-text'>
                {x}
                </span>
            </a>
        </div>

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
            <NavBar activeKind={@props.kind}/>
            <div className='page-content'>
            {
                if not @state.connected
                    <div className='disconnected'>Disconnected.</div>
                else
                    switch @props.scope[0]
                        when 'number'
                            <NumberPage data={@state.data} scope={@props.scope} onchange={@onchange}/>
            }
            </div>
        </div>

TopPage = React.createClass
    page_kind: ->
        res = if not @props.scope[0]?
            'active'
        else
            @props.scope[0]

    render: ->
        <div className={'theme-'+@page_kind()}>
            <DataPage scope={@props.scope} kind={@page_kind()}/>
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
    # redirect pages like '/lovecat.number.xx.xxx' to '/number.xx.xxx'
    url = document.location.pathname
    x = url.match(/^\/lovecat\.(.*)$/)
    if x then document.location.pathname = x[1]

    scope = utils.url_to_scope(document.location.pathname)
    React.initializeTouchEvents(true)
    React.render(<TopPage scope={scope}/>, document.getElementById('page'))
