"use strict";

angular.module('pagerbot-admin')
  .controller('PagerdutyCtrl', function($scope, $rootScope, pd, $http, $delayed_watch, $location) {
    $scope.status = 'saved';

    $delayed_watch($rootScope, 'pagerduty', function(value) {
      $scope.$save(value);
    });

    $scope.$save = function(pagerduty) {
      if (!pagerduty) pagerduty = $rootScope.pagerduty;
      console.log("Saving pagerduty settings:", pagerduty);
      $scope.status = 'saving';
      $rootScope.can_connect = false;

      $http.post('/api/pagerduty', pagerduty)
        .success(function(response) {
          $rootScope.pagerduty = response.saved;
          $rootScope.can_connect = response.can_connect;
          $scope.status = 'saved';
        });
    };
  });
