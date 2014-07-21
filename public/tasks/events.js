var seleniumChildProcesses = {};

module.exports = function(grunt) {
  grunt.event.on('selenium.start', function(target, process){
    grunt.log.ok('Bootstripe saw process for target: ' +  target);
    seleniumChildProcesses[target] = process;
  });

  grunt.event.on('huxley.fail', function() {
    // Clean up selenium if we left it running after a failure.
    grunt.log.writeln('Attempting to clean up running selenium server.');
    for(var target in seleniumChildProcesses) {
      grunt.log.ok('Killing selenium target: ' + target);
      try {
        seleniumChildProcesses[target].kill('SIGTERM');
      }
      catch(e) {
        grunt.log.warn('Unable to stop selenium target: ' + target);
      }
    }
  });
};
