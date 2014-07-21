var LOCAL_TEST_URL = 'http://localhost:62000/';
var Sizes = require('../test/templates/sizes');

var os = require('os');

var localIpAddress;
var interfaces = os.networkInterfaces();
for (var k in interfaces) {
  for (var k2 in interfaces[k]) {
    var address = interfaces[k][k2];
    if (address.family == 'IPv4' && !address.internal) {
      localIpAddress = address.address;
      break;
    }
  }
  if (localIpAddress) break;
}

module.exports = function(grunt) {
  function nameFromFilepath(filepath) {
    return filepath.split('/').pop().split('.').shift();
  }

  grunt.registerTask('huxley:build', 'Builds Huxley test directories. (e.g. .hux directories for your new tests.) This is automatically called by updatediffs.', [
    'huxley:build_huxleyfile',
    'huxley:build_hux'
  ]);

  // For building Huxley deps.
  // These hux directories should be checked in.
  grunt.registerTask('huxley:build_hux', 'Builds .hux directories for Huxley testing, which should be checked in, based on Huxleyfile.json.', function() {
    var tests = grunt.file.readJSON('test/Huxleyfile.json');
    var huxFiles = {};
    grunt.file.expand(['test/**/*.hux/record.json']).forEach(function(huxFile) {
      huxFiles[huxFile] = 1;
    });
    var recordTemplate = grunt.file.read('./test/templates/record.json');

    var testPath, recordPath;
    tests.forEach(function(test) {
      recordPath = 'test/' + test.name + '.hux/record.json';
      if (!huxFiles[recordPath]) {
        grunt.log.writeln('Found missing record.json, creating: ', recordPath);
        grunt.file.write(recordPath, recordTemplate);
      }
    });
  });

  grunt.registerTask('huxley:build_huxleyfile', 'Builds Huxleyfile for all *.html files in the test directory. If a `--component` is passed in, will build a Huxleyfile specifying only the tests for that component (and any responsive tests for that component, if applicable)', function() {
    var tests = [];

    // If a component or test name to test is specified, only run tests for that component.
    var components = grunt.option('component');
    var specifiedTestName = grunt.option('testName');
    if (components && specifiedTestName) {
      grunt.fail.warn('You can specify either a component name or a test name, but not both!');
    }

    if (components) {
      components = components.split(',').map(function(component) {
        return component.replace(/[A-Z]/g, function($1, index) {
          if (index) {
            return '-' + $1.toLowerCase();
          } else {
            return $1.toLowerCase();
          }
        });
      });
    }

    // Add generated responsive tests.
    var responsiveMatch = /<title>.*responsive.*<\/title>/i;
    var fileContent, testName, testUrl;
    var baseUrl = LOCAL_TEST_URL;

    // Modify the url for tddium
    if (process.env.TDDIUM) {
      var newAddress = localIpAddress.replace(/\./g, '-') + '.tddiumworker.stripe.io';
      baseUrl = baseUrl.replace('localhost', newAddress);
      grunt.log.ok('Replacing localhost in Huxleyfile.json with: ' + newAddress);
    }

    grunt.file.expand(['test/**/*.html']).forEach(function(filepath) {
      fileContent = grunt.file.read(filepath);
      testName = nameFromFilepath(filepath);

      if (components && components.filter(function(component) { return testName.indexOf(component) !== -1; }).length === 0) {
        return;
      }

      if (specifiedTestName && specifiedTestName !== testName) {
        return;
      }

      testUrl = baseUrl + filepath;
      if (responsiveMatch.test(fileContent)) {
        Sizes.responsiveTestSizes.forEach(function(size) {
          tests.push({
            name: testName + '-' + size.name,
            screenSize: size.dimensions,
            url: testUrl
          });
        });
      }
      tests.push({
        name: testName,
        screenSize: Sizes.maxSupportedSize,
        url: testUrl
      });
    });

    grunt.file.write('./test/Huxleyfile.json', JSON.stringify(tests), {encoding: 'utf8'});
    grunt.log.ok('Finished writing Huxleyfile.json. (' + tests.length + ' tests' + (components ? ' for ' + components.join(', ') + ')' : ')'));
  });
};
