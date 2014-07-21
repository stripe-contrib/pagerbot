"use strict";

angular.module('pagerbot-admin')
  .controller('DeployCtrl', function ($scope) {
    $scope.app_name = window.location.hostname.split(".")[0];
    $scope.url_base = "https://dashboard.heroku.com/apps/";
    if (!$scope.app_name || window.location.hostname.indexOf("herokuapp.com") < 0) {
      $scope.found_app_name = false;
      $scope.dashboard_url = $scope.url_base;
      $scope.papertrail_url = $scope.url_base;
    } else {
      $scope.found_app_name = true;
      $scope.dashboard_url = $scope.url_base + $scope.app_name;
      $scope.papertrail_url = "https://addons-sso.heroku.com/apps/"+$scope.app_name+"/addons/papertrail:choklad";
      //"https://papertrailapp.com/systems/"+$scope.app_name+"/events";
    }
  });
