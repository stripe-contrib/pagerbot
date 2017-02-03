"use strict";

angular.module('pagerbot-admin')
  .factory('pagerduty_promise', function($http) {
    return $http.get('/api/pagerduty');
  })
  .factory('alias_manager', function($http, $delayed_watch, $filter, ngTableParams) {
    var setupTable = function(collection) {
      var table = new ngTableParams({
        page: 1,
        count: 100,
        sorting: { name: 'asc' }
      }, {
        counts: [],
        total: 1,
        getData: function($defer, params) {
          // use build-in angular filter
          var orderedData = params.sorting() ?
                              $filter('orderBy')(collection, params.orderBy()) :
                              collection;

          $defer.resolve(orderedData);
        }
      });
      return table;
    };

    var can_add_alias = function(to_add, collection) {
      if (!_.isString(to_add))
        return false;
      if (to_add.length < 1)
        return false;
      if (to_add == "Invalid expression")
        return false;

      return _.every(collection, function(member) {
        return _.every(member.aliases || [], function(alias) {
          return alias.name != to_add;
        });
      });
    };

    return function($scope, collection_name) {
      var collection = function() {
        return $scope[collection_name][collection_name];
      };

      $delayed_watch($scope, collection_name, function(value) {
        service.save(value);
      });

      var service = {};
      service.active_row = 0;
      service.table = setupTable(collection());

      service.save = function(collection) {
        console.log("Saving", collection_name, collection);

        $http.post('/api/'+collection_name, collection)
          .success(function(response) {
            console.debug("Save result:", response.saved);
            $scope[collection_name] = response.saved;
            if(!$scope.$$phase) $scope.$apply();
          });
      };

      service.add_alias = function(member_index, default_) {
        var member = collection()[member_index];
        var name = prompt("Enter new alias for "+member["name"], default_);

        if (name && can_add_alias(name, collection())) {
          var index = member.aliases.length;
          member.aliases.push({ name: name, automatic: false });

          // slightly racy
          $http.post('/api/normalize_strings', {strings: [name]})
            .success(function(strings) {
              member.aliases[index].name = strings.strings[0];
            });
        } else {
          console.log("Can't add alias", name, "for", member, _.clone(member.aliases));
        }
      };

      service.remove_alias = function(member_index, alias_index) {
        var member = collection()[member_index];
        member.aliases.splice(alias_index, 1);
      };

      service.evaluate = function(expression, data) {
        try {
          return _.template(expression, data);
        } catch(e) {
          return 'Invalid expression';
        }
      };

      service.mass_add_aliases = function(expression) {
        var names = [];
        var selected_members = [];
        _.each(collection(), function(member) {
          var result = service.evaluate(expression, member);
          if (result !== 'Invalid expression') {
            names.push(result);
            selected_members.push(member);
          }
        });

        console.log("Mass adding", expression, "for", selected_members, names, collection());
        // slightly racy
        $http.post('/api/normalize_strings', {strings: names})
          .success(function(result) {
            console.debug("Normalization results:", result);
            _.each(_.zip(result.strings, selected_members), function(pair) {
              var member = pair[1];
              if (can_add_alias(pair[0], collection()))
                member.aliases.push({ name: pair[0], automatic: true });
            });
          });
      };

      service.remove_mass_aliases = function() {
        if (confirm('Are you sure you want to delete all mass added aliases?')) {
          _.each(collection(), function(member) {
            member.aliases = _.filter(member.aliases, function(alias) {
              return !alias.automatic;
            });
          });
        }
      };

      return service;
    };
  });
