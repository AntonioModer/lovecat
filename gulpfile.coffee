gulp = require 'gulp'
browserify = require 'browserify'
watchify = require 'watchify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
livereload = require 'gulp-livereload'
uglify = require 'gulp-uglify'
shell = require 'gulp-shell'
assign = require 'lodash.assign'
less = require 'gulp-less'
rename = require 'gulp-rename'

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

bundle_css_watch = (watch_glob, src, dst_path, dst_file) ->
    rebundle = ->
        gulp.src(src)
            .pipe(less(paths: ['./node_modules']))
            .on('error', handle_error)
            .pipe(rename(dst_file))
            .pipe(gulp.dest(dst_path))
            .pipe(livereload())
    gulp.watch watch_glob, ->
        do rebundle
    do rebundle

gulp.task 'default', ->
    livereload.listen()
    bundle_js_watch  './cjsx/main.cjsx', 'cjsx', 'generated.js'
    bundle_css_watch './less/*.less', 'less/main.less', 'less', 'generated.css'
