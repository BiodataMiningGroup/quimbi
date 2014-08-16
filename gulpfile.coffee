"use strict"

pack			= require './package.json'
gulp 			= require 'gulp'
del			= require 'del'
concat 		= require 'gulp-concat'
symlink		= require 'gulp-symlink'

coffee 		= require 'gulp-coffee'
ngAnnotate	= require 'gulp-ng-annotate'
uglify 		= require 'gulp-uglify'

less			= require 'gulp-less'
autoprefixer= require 'gulp-autoprefixer'
minifyCSS	= require 'gulp-minify-css'

basePaths =
	build: 		"./build/"
	source: 		"./src/"
	data:			"./data/"
	colorMaps:	"./color-maps/"

paths =
	build:
		fonts:		"#{basePaths.build}fonts/"
		scripts:		"#{basePaths.build}js/"
		shader:		"#{basePaths.build}shader/"
		styles:		"#{basePaths.build}css/"
		templates:	"#{basePaths.build}templates/"
		views:		"#{basePaths.build}views/"
	source:
		fonts:		"#{basePaths.source}fonts/"
		scripts:		"#{basePaths.source}scripts/"
		shader:		"#{basePaths.source}shader/"
		styles:		"#{basePaths.source}styles/"
		templates:	"#{basePaths.source}templates/"
		views:		"#{basePaths.source}views/"

gulp.task "copyScripts", ->
	del.sync "#{paths.build.scripts}lib"
	gulp.src "#{paths.source.scripts}lib/**/*"
		.pipe gulp.dest "#{paths.build.scripts}lib"

gulp.task "scripts", ->	
	del.sync "#{paths.build.scripts}*.js"
	gulp.src "#{paths.source.scripts}**/*.coffee"
		.pipe coffee()
		.pipe ngAnnotate()
		.pipe concat "#{pack.name}.annotated.js"
		.pipe gulp.dest paths.build.scripts
		.pipe concat "#{pack.name}.min.js"
		.pipe uglify()
		.pipe gulp.dest paths.build.scripts

gulp.task "copyStyles", ->
	del.sync "#{paths.build.styles}lib"
	gulp.src "#{paths.source.styles}lib/**/*"
		.pipe gulp.dest "#{paths.build.styles}lib"

gulp.task "styles", ->
	del.sync "#{paths.build.styles}*.css"
	gulp.src "#{paths.source.styles}main.less"
		.pipe less()
		.pipe autoprefixer()
		.pipe concat "#{pack.name}.css"
		.pipe gulp.dest paths.build.styles
		.pipe concat "#{pack.name}.min.css"
		.pipe minifyCSS()
		.pipe gulp.dest paths.build.styles

gulp.task "copyFonts", ->
	del.sync paths.build.fonts
	gulp.src "#{paths.source.fonts}**/*"
		.pipe gulp.dest paths.build.fonts

gulp.task "copyShader", ->
	del.sync paths.build.shader
	gulp.src "#{paths.source.shader}**/*"
		.pipe gulp.dest paths.build.shader

gulp.task "copyTemplates", ->
	del.sync paths.build.templates
	gulp.src "#{paths.source.templates}**/*"
		.pipe gulp.dest paths.build.templates

gulp.task "copyViews", ->
	del.sync paths.build.views
	gulp.src "#{paths.source.views}**/*"
		.pipe gulp.dest paths.build.views

gulp.task "copyBase", ->
	del.sync "#{paths.build}index.html"
	gulp.src "#{basePaths.source}index.html"
		.pipe gulp.dest basePaths.build

gulp.task "links", ->
	gulp.src basePaths.data
		.pipe symlink "#{basePaths.build}"
	gulp.src basePaths.colorMaps
		.pipe symlink "#{basePaths.build}"

gulp.task "watch", ->
	gulp.watch "#{paths.source.scripts}lib/**/*", ["copyScripts"]
	gulp.watch "#{paths.source.scripts}**/*.coffee", ["scripts"]
	gulp.watch "#{paths.source.styles}lib/**/*", ["copyStyles"]
	gulp.watch "#{paths.source.styles}**/*.less", ["styles"]
	gulp.watch "#{paths.source.fonts}**/*", ["copyFonts"]
	gulp.watch "#{paths.source.shader}**/*", ["copyShader"]
	gulp.watch "#{paths.source.templates}**/*", ["copyTemplates"]
	gulp.watch "#{paths.source.views}**/*", ["copyViews"]
	gulp.watch "#{basePaths.source}index.html", ["copyBase"]

gulp.task "build", [
	"links"
	"copyScripts"
	"scripts"
	"copyStyles"
	"styles"
	"copyFonts"
	"copyShader"
	"copyTemplates"
	"copyViews"
	"copyBase"
]

gulp.task "default", [
	"watch"
	"build"
]