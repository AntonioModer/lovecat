React = require('react')
widgets = require('./widgets')
_ = require('lodash')
utils = require('./utils')

GridPage = React.createClass
    render: ->
        data = @props.data

        <div>
        {
            if data.length is 0
                <div className='no-results'>
                    no such parameters.
                </div>
        }
        </div>

module.exports = GridPage