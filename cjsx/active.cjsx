_ = require 'lodash'
utils = require './utils'
widgets = require './widgets'
React = require 'react'

ActivePage = React.createClass
    getInitialState: ->
        connected: false
        active_list: []
        filter: ''

    check_sync: ->
        return if @syncing

        if not @remote_instance_num?
            @setState connected: false
            return

        if @instance_num is @remote_instance_num and
           @active_version >= @remote_active_version
            if not @state.connected
                @setState connected: true
            return

        mem_instance_num = @remote_instance_num
        mem_active_version = @remote_active_version

        console.log 'refetch'
        @syncing = true
        utils.fetch_active (data) =>
            console.log 'done'
            @syncing = false
            @instance_num = mem_instance_num
            @active_version = mem_active_version
            @setState
                connected: true
                active_list: data
            setTimeout (=> do @check_sync), 0

    fetch_status: ->
        on_ok = (x) =>
            @remote_active_version = x.active_version
            @remote_instance_num = x.instance_num
            do @check_sync
        on_fail = =>
            @remote_active_version = null
            @remote_instance_num = null
            do @check_sync
        utils.fetch_status on_ok, on_fail

    componentWillMount: ->
        @active_version = 0
        @instance_num = null
        @remote_active_version = null
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
            <widgets.NavBar activeKind='active'/>
            <div className='page-content'>
                <div className='page-header'>
                    <div className='page-title'>
                        active namespaces
                    </div>
                    <div className='page-filter'>
                        <input type='text' placeholder='type to filter..' value={@state.filter} onChange={@onfilter}/>
                    </div>
                    &nbsp;
                </div>
            {
                if not @state.connected
                    <div className='disconnected'>disconnected</div>
                else
                    input = @state.filter
                    active_list = _.filter(@state.active_list, ((v) -> utils.scope_contains input, v))
                    active_list.sort(utils.scope_compare)
                    active_list.map (X, K) =>
                        <div key={K} className='active-entry'>
                            <div className='ball'/>
                            <div className='entry-text'>
                                <widgets.Scope scope={X}/>
                            </div>
                        </div>
            }
            </div>
        </div>

module.exports = ActivePage