'use strict'

module.exports = (grunt) ->
	require('matchdep').filterDev('grunt-*').forEach grunt.loadNpmTasks

	grunt.initConfig
		buildDir: './build'
		srcDir: './src'
		tmpDir: '.tmp'
		pkg: grunt.file.readJSON 'package.json'
		src:
			coffee: 'scripts/**/*.coffee'
			less: 'styles/main.less'
			html: '**/*.html'
			shader: 'shader/**/*.glsl'
			fonts: 'fonts/**/*'
		clean:
			tmp: [ '.tmp' ]

		recess:
			build:
				src: [ '<%= srcDir %>/<%= src.less %>' ],
				dest: '<%= tmpDir %>/css/<%= pkg.name %>.css',
				options:
					compile: true
					compress: true

		autoprefixer:
			multiple_files:
				flatten: true
				expand: true					
				src:  '<%= tmpDir %>/css/*.css'
				dest: '<%= buildDir %>/css/'

		coffee:
			build:
				options:
					bare: true
				files: [
					expand: true,
					cmd: 'coffee',
					src: [ '<%= srcDir %>/<%= src.coffee %>' ],
					dest: '.tmp/js/',
					ext: '.js'
				]

		concat:
			build:
				src: [
					'module.prefix'
					'.tmp/js/**/*.js'
					#'<%= src.js %>'
					'module.suffix'
				]
				dest: '<%= tmpDir %>/js/<%= pkg.name %>.js'

		# Annotate angular sources
		ngmin:
			build:
				src: [ '<%= tmpDir %>/js/<%= pkg.name %>.js' ]
				dest: '<%= buildDir %>/js/<%= pkg.name %>.annotated.js'

		# Minify the sources!
		uglify:
			build:
				files:
					'<%= buildDir %>/js/<%= pkg.name %>.min.js': [ '<%= buildDir %>/js/<%= pkg.name %>.annotated.js' ]
		# Copy files that don't need further processing
		copy:
			css:
				files: [
					cwd: '<%= srcDir %>/styles/lib'
					src: '*.css'
					dest: '<%= buildDir %>/css'
					expand: true
				]
			js:
				files: [
					cwd: '<%= srcDir %>/scripts/lib'
					src: '*.js'
					dest: '<%= buildDir %>/js'
					expand: true
				]
			main:
				files: [
					cwd: '<%= srcDir %>'
					src: [ '<%= src.html %>', '<%= src.shader %>', '<%= src.fonts %>']
					dest: '<%= buildDir %>'
					expand: true
				]

		delta:
			options:
				livereload: true
			main:
				files: [ '<%= srcDir %>/<%= src.html %>', '<%= srcDir %>/<%= src.shader %>', '<%= srcDir %>/<%= src.fonts %>' ]
				tasks: [ 'copy:main' ]
			css:
				files: [ '<%= srcDir %>/styles/vendor/*.css' ]
				tasks: [ 'copy:css' ]
			js:
				files: [ '<%= srcDir %>/scripts/vendor/*.js' ]
				tasks: [ 'copy:js' ]
			coffee:
				files: [ '<%= srcDir %>/<%= src.coffee %>' ]
				tasks: [
					'clean'
					'coffee'
					'concat'
					'ngmin'
					'uglify'
				]
			less:
				files: [ '<%= srcDir %>/<%= src.less %>' ]
				tasks: [ 'recess', 'autoprefixer' ]



	grunt.renameTask 'watch', 'delta'
	grunt.registerTask 'watch', [
		'build'
		'delta'
	]

	# The default task is to build.
	grunt.registerTask 'default', [ 'build' ]
	grunt.registerTask 'build', [
		'clean'
		'copy'
		'recess'
		'autoprefixer'
		'coffee'
		'concat'
		'ngmin'
		'uglify'
	]
