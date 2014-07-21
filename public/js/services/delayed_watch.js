"use strict";

angular.module('pagerbot-admin')
  .factory('$delayed_watch', function() {
    return function(scope, selector, on_change) {
      var timer = null, first = true;

      scope.$watch(selector, function(new_value, old_value) {
        if (!new_value) return;
        if (first) {
          first = false;
          return;
        }
        
        if (timer) clearTimeout(timer);
        timer = setTimeout(function() {
          timer = null;
          on_change(new_value);
        }, 1000);
      }, true);
    };
  });