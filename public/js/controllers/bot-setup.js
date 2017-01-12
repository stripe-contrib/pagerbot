"use strict";

angular.module('pagerbot-admin')
  .controller('BotSetupCtrl', function($scope, $rootScope, $http, $delayed_watch, $location) {
    // assume $rootScope.bot is populated in main.js
    $scope.status = 'saved';

    $scope.adapters = [
      {value: 'slack-rtm', name: 'Slack Real Time Messaging API'},
      {value: 'irc', name: 'IRC'},
      {value: 'hipchat', name: 'HipChat'},
      {value: 'slack', name: 'Slack Events API'},
    ];

    // when we change the values, save!
    $delayed_watch($rootScope, 'bot', function(value) {
      $scope.$save(value);
    });

    $scope.$save = function(bot_info) {
      if (!bot_info) bot_info = $rootScope.bot;
      console.log("Saving bot settings:", bot_info);
      $scope.status = 'saving';
      $scope.validateSlackConnection(bot_info);

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

    $scope.auth = {
      can_connect: 'no',
      last_valid_token: null,
      success_response: null,
      error_response: null
    }
    $scope.can_connect = 'no';
    $scope.last_valid_token = null;

    $scope.validateSlackConnection = function(bot_info) {
      if (bot_info.adapter === 'slack-rtm' || bot_info.adapter == 'slack') {
        var token = bot_info.slack.api_token;
        if (token === $scope.auth.last_valid_token) {
          $scope.auth.can_connect = 'yes';
          return;
        }
        if (!token || token.length < 10) {
          $scope.auth.can_connect = 'no';
          return;
        }
        $scope.auth.can_connect = 'validating';
        $http.get("https://slack.com/api/auth.test?token="+token)
          .success(function(response) {
            if (response.ok) {
              $scope.auth.can_connect = 'yes';
              $scope.auth.last_valid_token = token;
              $scope.auth.success_response = response;
            } else {
              $scope.auth.can_connect = 'no';
              $scope.auth.error_response = response;
            }
          });
      }
    }

    $scope.validateSlackConnection($rootScope.bot);
  });
