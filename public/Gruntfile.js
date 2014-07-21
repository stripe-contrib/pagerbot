function loadConfig(path) {
  var glob = require('glob');
  var object = {};
  var key;

  glob.sync('*', {cwd: path}).forEach(function(option) {
    key = option.replace(/\.js$/,'');
    object[key] = require(path + option);
  });

  return object;
}

module.exports = function(grunt) {

  // Project configuration.
  var config = {
    pkg: grunt.file.readJSON('package.json'),
    env: process.env
  };

  // Load up configs.
  grunt.util._.extend(config, loadConfig('./tasks/options/'));
  grunt.initConfig(config);

  // Load custom tasks.
  grunt.loadTasks('tasks');

  // Load npm tasks. These are the ones defined in devDependencies in our package.json.
  require('load-grunt-tasks')(grunt);
};