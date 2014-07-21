module.exports = function(grunt) {
  grunt.registerTask('util:ensure_specificity_option', 'Ensures that a CSS component name or test name is passed in before running this task. This can be overridden with a `--force`.', function() {
    if (grunt.option('component')) {
      grunt.log.ok('Running task for component: ' + grunt.option('component'));
    } else if (grunt.option('testName')) {
      grunt.log.ok('Running task for test: ' + grunt.option('testName'));
    } else {
      grunt.fail.warn('Please specify a component (`--component=ComponentName`) or a test name (`--testName=test-name`) in order to perform this task.')
    }
  });
};
