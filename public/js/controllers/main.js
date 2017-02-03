"use strict";

angular.module('pagerbot-admin')
  .controller('MainController', function ($scope, $location, $rootScope, $http, pagerduty_promise) {
    $scope.isActive = function(r) {
      return r == $location.path();
    };

    $http.get('/api/bot').success(function(response) {
      console.log("Bot info:", response);
      $rootScope.bot = response;
    });

    $rootScope.pagerduty = null;
    $rootScope.can_connect = false;
    if (window.localStorage) {
      $rootScope.can_connect = localStorage.getItem('can_connect_to_pagerduty');
      console.log($rootScope.can_connect);
    }

    pagerduty_promise.success(function(response) {
      console.log("Pagerduty info:", response);
      $rootScope.pagerduty = response.pagerduty;
      $rootScope.can_connect = response.can_connect;
    });

    $rootScope.thisdomain = "https://"+window.location.host+"/";

    var first = true;
    $rootScope.$watch('can_connect', function(can_connect) {
      if (first) {
        first = false;
        return;
      }
      localStorage && localStorage.setItem('can_connect_to_pagerduty', can_connect);
    });

    $scope.goTo = function(target) {
      console.log("Nav to", target, $rootScope.can_connect);
      if ($rootScope.can_connect) $location.path(target);
    };
  });
