var webdriver = require('browserstack-webdriver');

module.exports = {
  options: {
    action: 'playback'
  },
  localsauce: {
    options: {
      browser: 'chrome',
      driver: function () {
        var capabilities = {
          'browserName' : 'chrome',
          'username' : 'bootstripe',
          'accessKey' : '516343e8-4c12-4518-aaa9-b3a2c5c43edd',
          'platform': 'OS X 10.6',
          'screen-resolution': '1920x1200',
          'tunnel-identifier': 'bootstripelocal' + process.env.USER,
          'version': '35',
          'name': 'Bootstripe for Local: ' + process.env.USER
        };

        return new webdriver.Builder().
          usingServer(
            'http://' +
            capabilities.username + ':' +
            capabilities.accessKey +
            '@ondemand.saucelabs.com/wd/hub'
          ).
          withCapabilities(capabilities).
          build();
      }
    },
    src: ['test']
  },
  localsauce_update: {
    options: {
      action: 'update',
      browser: 'chrome',
      driver: function () {
        var capabilities = {
          'browserName' : 'chrome',
          'username' : 'bootstripe',
          'accessKey' : '516343e8-4c12-4518-aaa9-b3a2c5c43edd',
          'platform': 'OS X 10.6',
          'screen-resolution': '1920x1200',
          'tunnel-identifier': 'bootstripelocal' + process.env.USER,
          'version': '35',
          'name': 'Bootstripe for Local (update): ' + process.env.USER
        };

        return new webdriver.Builder().
          usingServer(
            'http://' +
            capabilities.username + ':' +
            capabilities.accessKey +
            '@ondemand.saucelabs.com/wd/hub'
          ).
          withCapabilities(capabilities).
          build();
      }
    },
    src: ['test']
  },
  sauce: {
    options: {
      browser: 'chrome',
      driver: function () {
        var capabilities = {
          'browserName' : 'chrome',
          'username' : process.env.SAUCE_USERNAME,
          'accessKey' : process.env.SAUCE_ACCESS_KEY,
          'platform': 'OS X 10.6',
          'screen-resolution': '1920x1200',
          'version': '35',
          'tunnel-identifier': 'citunnel1.east',
          'name': 'Bootstripe for Tddium: ' + process.env.TDDIUM_SESSION_ID
        };

        return new webdriver.Builder().
          usingServer('http://ondemand.saucelabs.com/wd/hub').
          withCapabilities(capabilities).
          build();
      }
    },
    src: ['test']
  }
};
