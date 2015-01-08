React = require('react')
widgets = require('./widgets')
_ = require('lodash')

NumberGroup = React.createClass
    render: ->
        group = _.initial(@props.data[0].k)
        data = _.sortBy @props.data, 'k'
        <div>
            <div className='group-name'>
            {
                group.map (X, K) ->
                    <span key={K}>
                        <span>{ K isnt 0 and '.'}</span>
                        <span key={K}>{X}</span>
                    </span>
            }
            </div>
            {
                data.map (X, K) =>
                    name = _.last(X.k)
                    scope = X.k
                    <div key={name} className='group-entry'>
                        <div className='group-entry-header'>{name}</div>
                        <div className='group-entry-content'>
                            <widgets.Slider val={X.v} onchange={(v)=>@props.onchange(scope, v)}/>
                        </div>
                    </div>
            }
        </div>

NumberPage = React.createClass
    onchange: (val) ->
        @props.onchange String(val) if @props.onchange

    render: ->
        data = _.groupBy @props.data, (x) -> _.initial(x.k)
        groups = _.keys(data).sort()

        <div>
        {
            groups.map (X, K) =>
                <div key={K}>
                    <NumberGroup data={data[X]} onchange={@props.onchange}/>
                </div>
        }
        </div>

module.exports = NumberPage