module.exports = function(grunt) {
  grunt.registerTask('test', 'Runs Bootstripe CSS regression tests. This simulates what is run when testing on TDDIUM.', [
    'build',
    'connect:server_sauce',
    'huxley:build_huxleyfile',
    'sauce_tunnel',
    'huxley:localsauce',
    'sauce_tunnel_stop'
  ]);
  grunt.registerTask('test:notunnel', 'Runs Bootstripe tests without Sauce Labs tunnel.', [
    'build',
    'connect:server_sauce',
    'huxley:build_huxleyfile',
    'huxley:localsauce'
  ]);
  grunt.registerTask('test:updatediffs', 'Updates expected output for the given component (pass `--component=ComponentName`).', [
    'util:ensure_specificity_option',
    'build',
    'connect:server_sauce',
    'huxley:build',
    'sauce_tunnel',
    'huxley:localsauce_update',
    'sauce_tunnel_stop'
  ]);
  grunt.registerTask('test:updatediffs:notunnel', 'Updates expected output for the given component without Sauce Labs tunnel (pass `--component=ComponentName`).', [
    'util:ensure_specificity_option',
    'build',
    'connect:server_sauce',
    'huxley:build',
    'huxley:localsauce_update'
  ]);

  // Not to be called normally.
  grunt.registerTask('test_tddium', 'Test task for TDDIUM.', [
    'build',
    'connect:server_sauce',
    'huxley:build_huxleyfile',
    'huxley:sauce'
  ]);
};
