var catdoc = require('../doc/doc.js');
var path = require('path');

module.exports = function(grunt) {
  grunt.registerTask('catdoc', 'Generates documentation for CSS components marked with `@component`.', function() {
    grunt.config.requires('catdoc.dest');
    grunt.config.requires('catdoc.theme');

    var files = grunt.config('catdoc.files');
    var dest = path.resolve(grunt.config('catdoc.dest'));
    var theme = path.resolve(grunt.config('catdoc.theme'));
    var okay = this.async();

    var d = new catdoc.Doc();

    for (var i in files) {
      var expandedFiles = grunt.file.expand([files[i]]);
      var matches = files[i].match(/\*/);
      matchCount = matches ? matches.length : 0;
      for (var j in expandedFiles) {
        d.addFile(path.resolve(expandedFiles[j]), matchCount);
      }
    }

    d.copyTheme(theme, dest, okay);
    grunt.file.write(dest + '/index.html', d.generate(path.join(theme, 'index.html')));
  });
};
