

module.exports = (grunt) ->
  grunt.initConfig
    clean:
      dist: ['dist/']
      coffee: ['dist/*.coffee']

    watch:
      scripts:
        files: ['**/*.coffee', '**/*.html']
        tasks: ['build']

    coffee:
      compile:
        expand: true
        files: [
          'dist/ki-router.js': 'dist/ki-router.coffee'
          'dist/ki-router.min.js': 'dist/ki-router.noAssert.coffee',
          'spec/router_test.js': 'spec/router_test.coffee'
        ]

    uglify:
      dist:
        files: 
          'dist/ki-router.min.js': 'dist/ki-router.min.js'

    copy: 
      dist: 
        expand:true
        files:[
          'dist/ki-router.coffee': 'src/ki-router.coffee'
        ]

    connect:
      http80:
        options:
          port: 80
          base: '.'
      https443:
        options:
          protocol: 'https'
          port: 443
          base: '.'
      http8090:
        options:
          port: 8090
          base: '.'
      https8443:
        options:
          protocol: 'https'
          port: 8443
          base: '.'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks('grunt-contrib-watch')

  grunt.registerTask 'build', ['clean:dist', 'copy', 'removeAsserts', 'coffee', 'uglify', 'clean:coffee']
  grunt.registerTask 'default', ['build']

  grunt.registerTask 'removeAsserts', ->
    fs = require 'fs'
    file = fs.readFileSync('dist/ki-router.coffee', 'utf8')
    replacedData = file.replace(/assert.*/g, '')
    fs.writeFileSync('dist/ki-router.noAssert.coffee', replacedData);