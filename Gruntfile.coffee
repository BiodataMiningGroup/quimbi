'use strict'

module.exports = (grunt) ->
	require('matchdep').filterDev('grunt-*').forEach grunt.loadNpmTasks

	grunt.initConfig
		# declare directories
		buildDir: './build'
		srcDir: './src'
		tmpDir: '.tmp'
		colormapsDir: './color-maps'
		pkg: grunt.file.readJSON 'package.json'
		# declare source files
		src:
			coffee: 'scripts/**/*.coffee'
			less: 'styles/main.less'
			html: '**/*.html'
			shader: 'shader/**/*'
			fonts: 'fonts/**/*'
		# Clean the temporary directory
		clean:
			tmp: [ '.tmp' ]
			# deletes everything in build but the data directory
			build:
				# explicitly stating everything that should be deleted instead of excluding data from cleaning is on purpose
				src: [
					'<%= buildDir %>/css/'
					'<%= buildDir %>/fonts/'
					'<%= buildDir %>/index.html'
					'<%= buildDir %>/js/'
					'<%= buildDir %>/shader/'
					'<%= buildDir %>/templates/'
					'<%= buildDir %>/views/'
				]
		# Compile and uglify LESS
		recess:
			build:
				src: [ '<%= srcDir %>/<%= src.less %>' ],
				dest: '<%= tmpDir %>/css/<%= pkg.name %>.css',
				options:
					compile: true
					compress: true
		# Add browser-prefixes to special CSS attributes
		autoprefixer:
			multiple_files:
				flatten: true
				expand: true
				src:  '<%= tmpDir %>/css/*.css'
				dest: '<%= buildDir %>/css/'
		# Compile the CoffeeScript files
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
		# Concatenate the JavaScript files
		concat:
			build:
				src: [
					'module.prefix'
					'.tmp/js/**/*.js'
					#'<%= src.js %>'
					'module.suffix'
				]
				dest: '<%= tmpDir %>/js/<%= pkg.name %>.js'

		# Annotate angular sources to be able to uglify them
		ngmin:
			build:
				src: [ '<%= tmpDir %>/js/<%= pkg.name %>.js' ]
				dest: '<%= buildDir %>/js/<%= pkg.name %>.annotated.js'

		# Minify the sources
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
					src: [
						'<%= src.html %>'
						'<%= src.shader %>'
						'<%= src.fonts %>'
					]
					dest: '<%= buildDir %>'
					expand: true
				]
			cssimages:
				files: [
					cwd: '<%= srcDir %>/styles/lib/css-images'
					src: '*.png'
					dest: '<%= buildDir %>/css/images'
					expand: true
				]
			jsimages:
				files: [
					cwd: '<%= srcDir %>/styles/lib/js-images'
					src: '*.png'
					dest: '<%= buildDir %>/js/images'
					expand: true
				]
				
		# Declare files to watch for live reload
		delta:
			options:
				livereload: true
			main:
				files: [
					'<%= srcDir %>/<%= src.html %>'
					'<%= srcDir %>/<%= src.shader %>'
					'<%= srcDir %>/<%= src.fonts %>'
				]
				tasks: [ 'copy:main' ]
			css:
				files: [ '<%= srcDir %>/styles/lib/*.css' ]
				tasks: [ 'copy:css' ]
			js:
				files: [ '<%= srcDir %>/scripts/lib/*.js' ]
				tasks: [ 'copy:js' ]
			coffee:
				files: [ '<%= srcDir %>/<%= src.coffee %>' ]
				tasks: [
					'clean:tmp'
					'coffee'
					'concat'
					'ngmin'
					'uglify'
				]
			less:
				files: [ '<%= srcDir %>/styles/**/*.less' ]
				tasks: [ 'recess', 'autoprefixer' ]

	grunt.renameTask 'watch', 'delta'
	grunt.registerTask 'watch', [
		'build'
		'delta'
	]

	# The default task is to build.
	grunt.registerTask 'default', [ 'build' ]
	grunt.registerTask 'build', [
		'clean:tmp'
		'copy'
		'recess'
		'autoprefixer'
		'coffee'
		'concat'
		'ngmin'
		'uglify'
	]
	grunt.registerTask 'cleanbuild', [
		'clean:build'
		'build'
	]
