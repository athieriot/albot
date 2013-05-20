
'use strict'

/*global module:false*/
module.exports = function(grunt) {

  grunt.loadNpmTasks('grunt-mocha-cli');

  grunt.initConfig({
    mochacli: {
      options: {
        reporter: 'spec'
      },
      all: ['test/**/*.coffee']
    }
  });

  grunt.registerTask('test', ['mochacli']);
};