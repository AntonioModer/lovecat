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
fs = require 'fs'

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

bundle_js_production = (src, dst_path, dst_file, config_func) ->
    opts = extensions: ['.cjsx', '.jsx']
    b = browserify(src, opts=opts)
    b.transform('coffee-reactify')
    config_func(b) if config_func?
    b.bundle()
     .on('error', handle_error)
     .pipe(source(dst_file))
     .pipe(buffer())
     .pipe(uglify())
     .pipe(gulp.dest(dst_path))

bundle_css_production = (src, dst_path, dst_file) ->
    gulp.src(src)
        .pipe(less(compress: true, paths: ['./node_modules']))
        .on('error', handle_error)
        .pipe(rename(dst_file))
        .pipe(gulp.dest(dst_path))

gulp.task 'default', ->
    livereload.listen()
    bundle_js_watch  './cjsx/main.cjsx', 'cjsx', 'generated.js'
    bundle_css_watch './less/*.less', 'less/main.less', 'less', 'generated.css'

gulp.task 'build-js', ->
    bundle_js_production './cjsx/main.cjsx', 'cjsx', 'generated.min.js'

gulp.task 'build-css', ->
    bundle_css_production 'less/main.less', 'less', 'generated.min.css'

gulp.task 'check-env', ->
    if process.env.NODE_ENV isnt 'production'
        throw 'please set NODE_ENV to "production"'

gulp.task 'cut-lua', shell.task "sed '/--==--==--==--/,$d' src/lovecat.lua > lovecat.lua"

gulp.task 'build-lua', ['build-js', 'build-css', 'cut-lua'], ->
    js = fs.readFileSync('cjsx/generated.min.js')
    css = fs.readFileSync('less/generated.min.css')

    to_append = """
lovecat.pages["_default"] = lovecat.pages["_default"]:gsub('ADDITIONAL_SCRIPT', '')

lovecat.pages["_lovecat_/app.css"] = [=====[#{css}]=====]
lovecat.pages_mime["_lovecat_/app.css"] = 'text/css'
lovecat.pages["_lovecat_/app.js"] = [=====[#{js}]=====]

return lovecat
"""

    fs.appendFileSync('lovecat.lua', to_append)

gulp.task 'release', ['check-env', 'build-lua'], shell.task 'rm -rf lovecat.tar.bz2 && tar cjf lovecat.tar.bz2 lovecat.lua example/ LICENSE README.md'

