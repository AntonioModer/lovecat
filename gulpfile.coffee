gulp = require 'gulp'
browserify = require 'browserify'
watchify = require 'watchify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
livereload = require 'gulp-livereload'
uglify = require 'gulp-uglify'
shell = require 'gulp-shell'
assign = require 'lodash.assign'

handle_error = (err) ->
    console.log err.toString()
    @emit('end')

bundle_js_watch = (src, dst_path, dst_file, config_func) ->
    opts = extensions: ['.cjsx', '.jsx']
    opts = assign({}, watchify.args, opts)
    b = watchify(browserify(src, opts=opts))
    b.transform('coffee-reactify')
    config_func(b) if config_func?
    rebundle = ->
        b.bundle()
         .on('error', handle_error)
         .pipe(source(dst_file))
         .pipe(gulp.dest(dst_path))
         .pipe(livereload())
    b.on 'update', rebundle
    rebundle()

gulp.task 'default', ->
    livereload.listen()
    bundle_js_watch  './cjsx/main.cjsx', 'cjsx', 'generated.js'
    gulp.watch('css/*.css').on 'change', (evt) ->
        return if evt.type is 'deleted'
        livereload.changed(evt.path)
