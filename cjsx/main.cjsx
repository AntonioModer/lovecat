React = require('react')
domready = require('domready')
utils = require('./utils')
_ = require('lodash')
NumberPage = require('./number')
ActivePage = require('./active')
PointPage = require('./point')
ColorPage = require('./color')
GridPage = require('./grid')
widgets = require './widgets'

DataPage = React.createClass
    getInitialState: ->
        connected: false
        data: []
        filter: ''

    check_sync: ->
        return if @syncing

        if not @remote_instance_num?
            @setState connected: false
            return

        return if @pending_changes isnt 0

        if @instance_num is @remote_instance_num and
           @data_version >= @remote_data_version
            if not @state.connected
                @setState connected: true
            return

        mem_instance_num = @remote_instance_num
        mem_data_version = @remote_data_version

        console.log 'refetch'
        @syncing = true
        utils.fetch_view @props.scope, (data) =>
            @syncing = false
            @instance_num = mem_instance_num
            @data_version = mem_data_version
            @setState
                connected: true
                data: data
            setTimeout (=> do @check_sync), 0

    fetch_status: ->
        on_ok = (x) =>
            @remote_data_version = x.data_version
            @remote_instance_num = x.instance_num
            do @check_sync
        on_fail = =>
            @remote_data_version = null
            @remote_instance_num = null
            do @check_sync
        utils.fetch_status on_ok, on_fail

    onchange: (k, v) ->
        @pending_changes += 1
        on_ok = =>
            @pending_changes -=1
            @data_version += 1
            do @check_sync
        on_fail = =>
            @pending_changes -=1
            do @check_sync
        utils.send_update k, utils.format_lua_value(k[0], v), on_ok, on_fail
        for x in @state.data
            if _.isEqual(x.k, k)
                x.v = v
                break
        do @forceUpdate

    componentWillMount: ->
        @pending_changes = 0
        @data_version = 0
        @instance_num = null
        @remote_data_version = null
        @remote_instance_num = null
        @syncing = false

    componentDidMount: ->
        do @fetch_status
        @timer = setInterval (=> do @fetch_status), 500

    componentWillUnmount: ->
        clearInterval @timer

    onfilter: (evt) ->
        @setState filter:evt.target.value

    render: ->
        <div>
            <widgets.NavBar activeKind={@props.kind}/>
            <div className='page-content'>
                <div className='page-header'>
                    <div className='page-title'>
                        <widgets.Scope scope={@props.scope} />
                    </div>
                    {
                        if not utils.is_leaf_scope(@props.scope)
                            <div className='page-filter'>
                                <input type='text' placeholder='type to filter..'
                                    value={@state.filter} onChange={@onfilter}/>
                            </div>
                    }
                    &nbsp;
                </div>
            {
                if not @state.connected
                    <div className='disconnected'>disconnected</div>
                else
                    input = @state.filter
                    data = _.filter(@state.data, ((v) -> utils.scope_contains input, v.k))
                    data = data.sort (a,b) -> utils.scope_compare(a.k, b.k)

                    switch @props.scope[0]
                        when 'number'
                            <NumberPage data={data} scope={@props.scope}
                                onchange={@onchange}/>
                        when 'point'
                            <PointPage data={data} scope={@props.scope}
                                onchange={@onchange}/>
                        when 'color'
                            <ColorPage data={data} scope={@props.scope}
                                onchange={@onchange}/>
                        when 'grid'
                            <GridPage data={data} scope={@props.scope}
                                onchange={@onchange}/>
            }
            </div>
        </div>

TopPage = React.createClass
    set_window_title: ->
        if @props.scope[0]?
            document.title = 'lovecat.' + utils.scope_to_string @props.scope

    page_kind: ->
        res = if not @props.scope[0]?
            'active'
        else
            @props.scope[0]

    componentDidMount: ->
        do @set_window_title

    render: ->
        <div className={'theme-'+@page_kind()}>
        {
            if @page_kind() is 'active'
                <ActivePage/>
            else
                <DataPage scope={@props.scope} kind={@page_kind()}/>
        }
        </div>

domready ->
    # redirect pages like '/lovecat.number.xx.xxx' to '/number.xx.xxx'
    url = document.location.pathname
    x = url.match(/^\/lovecat\.(.*)$/)
    if x then document.location.pathname = x[1]

    scope = utils.url_to_scope(document.location.pathname)
    React.initializeTouchEvents(true)
    React.render(<TopPage scope={scope}/>, document.getElementById('page'))
