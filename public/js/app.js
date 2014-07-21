"use strict";

(function() {
  function get_promise(endpoint) {
    return function($http) {
      return $http.get(endpoint);
    };
  }

  angular.module('pagerbot-admin', ['ngRoute', 'ngTable', 'angular-loading-bar'])
    .config(function ($routeProvider) {
      $routeProvider
        .when('/intro', {
          templateUrl: 'views/intro.html',
          controller: 'PagerdutyCtrl',
          resolve: {
            pd: function(pagerduty_promise) {
              return pagerduty_promise;
            }
          }
        })
        .when('/bot-setup', {
          templateUrl: 'views/bot.html',
          controller: 'BotSetupCtrl',
          resolve: {
            bot_info: get_promise('/bot')
          }
        })
        .when('/plugin-setup', {
          templateUrl: 'views/plugins.html',
          controller: 'PluginSetupCtrl',
          resolve: {
            plugin_info: get_promise('/plugins')
          }
        })
        .when('/user-aliases', {
          templateUrl: 'views/users.html',
          controller: 'UserAliasCtrl',
          resolve: {
            users: get_promise('/users')
          }
        })
        .when('/schedule-aliases', {
          templateUrl: 'views/schedules.html',
          controller: 'ScheduleAliasCtrl',
          resolve: {
            schedules: get_promise('/schedules')
          }
        })
        .when('/deploy', {
          templateUrl: 'views/deploy.html',
          controller: 'DeployCtrl'
        })
        .otherwise({
          redirectTo: '/intro'
        });
    });
})();