module PagerBot::Plugins
  class AddAlias
    include PagerBot::PluginBase
    responds_to :queries, :manual
    description "Add aliases for users or schedules."

    def initialize(config)
    end

    def self.manual
      {
        description: "Add alias for user or schedule",
        syntax: ["alias USER_OR_SCHEDULE as NEW_ALIAS"],
        examples: [
          "alias karl@mycompany.com as thebestkarl",
          "alias PIBRSYV as triage"
        ]
      }
    end

    def parse(query)
      return unless query[:command] == "alias"

      parse_stage = :searched_alias
      names = {
        searched_alias: [],
        new_alias: []
      }

      query[:words].each do |word|
        case word
        when 'as'
          parse_stage = :new_alias
        else
          names[parse_stage] << word
        end
      end

      names.each do |stage, nameparts|
        names[stage] = nameparts.join(' ')
      end
    end

    def matches_in(collection, nameCandidate)
      fields_to_scan = [:email, :name, :id]

      normalizedCandidate = PagerBot::Utilities.normalize(nameCandidate)

      collection.select do |member|
        fields_to_scan.any? do |field|
          member[field] && PagerBot::Utilities.normalize(member[field]) == normalizedCandidate
        end
      end
    end

    +PagerBot::Utilities::DispatchMethod
    def dispatch(query, event_data)
      users_matches = matches_in(pagerduty.users.list, query[:searched_alias])
      schedule_matches = matches_in(pagerduty.schedules.list, query[:searched_alias])
      new_alias = PagerBot::Utilities.normalize(query[:new_alias])

      if users_matches.empty? && schedule_matches.empty?
        return "Could not find user or schedule #{query[:searched_alias]}."
      end
      # Ambigious matches.
      if users_matches.length + schedule_matches.length > 1
        return "Field #{query[:searched_alias]} is ambiguous."
      end
      # base case, only one find!
      store = PagerBot::DataStore.new
      if users_matches.first
        user = users_matches.first
        user.aliases << {name: new_alias, automated: false}
        store.update_listed_collection('users', user.to_h)
        PagerBot.reload_configuration!
        return "Added a new alias for user #{user.name}."
      else
        schedule = schedule_matches.first
        schedule.aliases << {name: new_alias, automated: false}
        store.update_listed_collection('schedules', schedule.to_h)
        PagerBot.reload_configuration!
        return "Added a new alias for schedule #{schedule.name}."
      end
    end
  end
end
