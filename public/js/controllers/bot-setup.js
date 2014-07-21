"use strict";

angular.module('pagerbot-admin')
  .controller('BotSetupCtrl', function($scope, $rootScope, $http, $delayed_watch, $location) {
    // assume $rootScope.bot is populated in main.js
    $scope.status = 'saved';

    // when we change the values, save!
    $delayed_watch($rootScope, 'bot', function(value) {
      $scope.$save(value);
    });

    $scope.$save = function(bot_info) {
      if (!bot_info) bot_info = $rootScope.bot;
      console.log("Saving bot settings:", bot_info);
      $scope.status = 'saving';
      $scope.can_connect = false;

      $http.post('/bot', bot_info)
        .success(function(response) {
          $rootScope.bot = response.saved;
        });
    };

    // TODO: sanitize name!
    $scope.add_channel = function() {
      var chan = prompt("Enter channel name", "sys");
      if (chan && !_.contains($rootScope.bot.channels, chan))
        $rootScope.bot.channels.push(chan);
    };

    $scope.remove_channel = function(chan, index) {
      $rootScope.bot.channels.splice(index, 1);
    };
  });