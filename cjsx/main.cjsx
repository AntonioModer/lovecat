React = require('react')
domready = require('domready')

Test = React.createClass
    render: ->
        <div className='abc'>
            hello!
        </div>

domready ->
    React.render(<Test/>, document.getElementById('page'))