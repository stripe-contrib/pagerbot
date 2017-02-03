"use strict";

angular.module('pagerbot-admin')
  .controller('PluginSetupCtrl', function($scope, plugin_info, $http, $delayed_watch, $location) {
    $scope.plugins = plugin_info.data;
    console.debug("Plugins:", $scope.plugins);

    // when we change the values, save!
    $delayed_watch($scope, 'plugins', function(value) {
      $scope.$save(value);
    });

    $scope.$save = function(plugin_info) {
      if (!plugin_info) plugin_info = $scope.plugins;
      console.log("Saving plugin settings:", plugin_info);
      $scope.status = 'saving';

      $http.post('/api/plugins', plugin_info)
        .success(function(response) {
          $scope.plugins = response.saved;
        });
    };

    $scope.continue = function() {
      $location.path('/chatbot-settings');
    };
  });
