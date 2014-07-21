module.exports = function(grunt) {
  // Default tasks for building the guide.
  grunt.registerTask('build', 'Builds bootstripe.css and its style guide.', [
    'clean',
    'mkdir',
    'broccoli_build',
    'catdoc',
    'copy',
    'symlink'
  ]);

  grunt.registerTask('serve', 'Serves Bootstripe and Bootstripe docs.', [
    'build',
    'connect:server',
    'watch'
  ]);
};
