module PagerBot::Plugins
  class Reload
    include PagerBot::PluginBase
    responds_to :queries, :manual
    description "Update list of pagerduty schedules and linked accounts"

    def initialize(config)
    end

    def self.manual
      {
        description: Reload.description,
        # syntax: ["reload"],
        examples: ["reload"]
      }
    end

    def parse(query)
      # get karl because everything is on fire
      return {} if query[:command] == "reload"
    end

    +PagerBot::Utilities::DispatchMethod
    def dispatch(query, event_data)
      store = PagerBot::DataStore.new
      users_update = store.update_collection!('users', true)
      schedule_update = store.update_collection!('schedules', true)

      vars = {
        added_users: users_update[1],
        removed_users: users_update[2],
        added_schedules: schedule_update[1],
        removed_schedules: schedule_update[2]
      }

      PagerBot.reload_configuration!

      render 'reload', vars
    end
  end
end
