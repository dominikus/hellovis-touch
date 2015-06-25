gulp = require 'gulp'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
notify = require 'gulp-notify'
sourcemaps = require 'gulp-sourcemaps'
bower = require 'main-bower-files'
sass = require 'gulp-ruby-sass'
fileinclude = require 'gulp-file-include'
replace = require 'gulp-replace-task'
connect = require 'gulp-connect'
del = require 'del'
uglify = require 'gulp-uglify'
imagemin = require 'gulp-imagemin'
sequence = require 'run-sequence'
sftp = require 'gulp-sftp'
bump = require 'gulp-bump'
git = require 'gulp-git'

pkg = require './package.json'

banner = """
#{pkg.name}
authors: #{pkg.authors}
version: #{pkg.version}
date: #{new Date()}
"""

configDev =
	"mode": "dev"	# dev|dist
	"target": "dev"	# dev|dist
	"bowerDir": "bower_components"
	"variables":
		"SITE_NAME": "hello"
		"GA_ID": "_"
		"GA_URL": "_"
		"FB_APP_ID": "_"
		"BANNER": banner
		"VERSION": pkg.version

configDist =
	"mode": "dist"	# dev|dist
	"target": "dist"	# dev|dist
	"bowerDir": "bower_components"
	"variables":
		"SITE_NAME": "hello"
		"GA_ID": "_"
		"GA_URL": "_"
		"FB_APP_ID": "_"
		"BANNER": banner
		"VERSION": pkg.version


config = configDev

onError = (err) -> notify().write err


remotePath = "INSERT REMOTE PATH"

gulp.task 'sftp-deploy', ['minify'], ->
	gulp.src config.target + '/**/*!(.sass-cache)*'
	.pipe sftp
		host: 'INSERT SERVER NAME'
		user: 'INSERT USER NAME'
		port: 22
		key: './key'
		remotePath: "#{remotePath}"


gulp.task 'bower', ->
	gulp.src bower()
	.pipe connect.reload()
	.pipe concat "libs.js"
	.pipe gulp.dest config.target + '/js'

gulp.task 'coffee', ->
	gulp.src ['src/coffee/main.coffee', 'src/coffee/**/!(main)*.coffee']
	.pipe concat "main.js"
	.pipe connect.reload()
	.pipe sourcemaps.init()
	.pipe coffee bare:false
	.on "error", notify.onError "Error: <%= error.message %>"
	.pipe sourcemaps.write()
	.pipe gulp.dest config.target + '/js'
	#.pipe notify "coffee's ready!"


gulp.task 'sass', ->
	sassStyle = "nested"
	sassStyle = "compressed" if config.mode == "dist"

	sass 'src/sass',
		style: sassStyle
		loadPath: [
			'./src/sass'
			config.bowerDir + '/bootstrap-sass/assets/stylesheets'
			require('node-bourbon').includePaths[0]
		]
	.on "error", notify.onError "Error: <%= error.message %>"
	.pipe connect.reload()
	.pipe gulp.dest config.target + '/css'


gulp.task 'copy', ->
	gulp.src "src/assets/**/*"
	.pipe gulp.dest config.target + '/assets'

	gulp.src "src/js/**/*"
	.pipe gulp.dest config.target + '/js'

	gulp.src "src/data/**/*"
	.pipe gulp.dest config.target + '/data'

	gulp.src "src/css/**/*"
	.pipe gulp.dest config.target + '/css'

	gulp.src "src/fonts/**/*"
	.pipe gulp.dest config.target + '/fonts'

	gulp.src "src/*.{png,jpg,gif,ico}"
	.pipe gulp.dest config.target + '/'

	gulp.src "./"
	.pipe connect.reload()

gulp.task 'includereplace', ->
	gulp.src ["src/html/**/!(_)*.html", "src/.htaccess"]
	.pipe fileinclude
		prefix: '@@'
		basepath: '@file'
	.pipe replace
		patterns: [ json: config.variables ]
	.pipe connect.reload()
	.pipe gulp.dest config.target + '/'

gulp.task 'uglify', ['initial-build'], ->
	gulp.src config.target + '/js/**/*.js'
	.pipe uglify()
	.on "error", notify.onError "Error: <%= error.message %>"
	.pipe gulp.dest config.target + '/js'

gulp.task 'imagemin', ['initial-build'], ->
	gulp.src config.target + '/assets/**/*.{png,jpg,gif}'
	.pipe imagemin()
	.on "error", notify.onError "Error: <%= error.message %>"
	.pipe gulp.dest config.target + '/assets'


gulp.task 'clean', (cb) ->
	del [ config.target ], cb

gulp.task 'initial-build', ['clean'], (cb) ->
	if config.mode == 'dist'
		sequence('copy', 'coffee', ['includereplace', 'sass', 'bower'], cb)
	else
		sequence('copy', ['includereplace', 'coffee', 'sass', 'bower'], cb)

gulp.task 'watch', ['initial-build'], ->
	gulp.watch 'bower_components/**', ['bower']
	gulp.watch 'src/coffee/**', ['coffee']
	gulp.watch 'src/sass/**', ['sass']
	gulp.watch 'src/assets/**', ['copy']
	gulp.watch 'src/js/**/*', ['copy']
	gulp.watch 'src/data/**', ['copy']
	gulp.watch 'src/html/**/*.html', ['includereplace']
	gulp.watch 'src/css/**/*', ['copy']
	gulp.watch 'src/font/**/*', ['copy']

gulp.task 'minify', ['uglify', 'imagemin']


# main tasks:
gulp.task 'dev', ->
	config = configDev
	sequence 'watch'

gulp.task 'dist', ->
	config = configDist
	sequence 'minify'

gulp.task 'ftp', ->
	config = configDist
	sequence 'sftp-deploy'

gulp.task 'bump', () ->
	gulp.src ['./package.json', './bower.json']
	.pipe bump()
	.pipe gulp.dest('./')

gulp.task 'bump:major', () ->
	gulp.src ['./package.json', './bower.json']
	.pipe bump
		type: 'major'
	.pipe gulp.dest('./')

gulp.task 'bump:minor', () ->
	gulp.src ['./package.json', './bower.json']
	.pipe bump
		type: 'minor'
	.pipe gulp.dest('./')


gulp.task 'tag', () ->
	pkg = require './package.json'
	v = 'v' + pkg.version
	message = 'Release ' + v

	git.commit message
	git.tag v, message
	git.push 'origin', 'master', {args: '--tags'}
