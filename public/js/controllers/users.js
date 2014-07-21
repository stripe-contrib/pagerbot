"use strict";

angular.module('pagerbot-admin')
  .controller('UserAliasCtrl', function($scope, users, alias_manager) {
    $scope.users = users.data;
    $scope.url_base = "https://"+users.data.pagerduty.subdomain+".pagerduty.com";
    console.debug("Users:", $scope.users);

    $scope.mass = {
      expression: "<%= email.split('@')[0] %>"
    };

    $scope.manager = alias_manager($scope, 'users');
    
    $scope.add_alias = function(user_index) {
      var default_ = $scope.users.users[user_index].name;
      $scope.manager.add_alias(user_index, default_);
    };
  });
  