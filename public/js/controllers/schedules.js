"use strict";

angular.module('pagerbot-admin')
  .controller('ScheduleAliasCtrl', function($scope, schedules, alias_manager) {
    $scope.schedules = schedules.data;
    $scope.url_base = "https://"+schedules.data.pagerduty.subdomain+".pagerduty.com";
    console.debug("schedules:", $scope.schedules);

    $scope.mass = {
      expression: "<%= name %>"
    };

    $scope.manager = alias_manager($scope, 'schedules');
    
    $scope.add_alias = function(schedule_index) {
      var default_ = $scope.schedules.schedules[schedule_index].name;
      $scope.manager.add_alias(schedule_index, default_);
    };
  });