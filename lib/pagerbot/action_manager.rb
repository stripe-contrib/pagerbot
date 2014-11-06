module PagerBot
  # This class takes action/prepares response based on parsed queries.
  class ActionManager
    extend MethodDecorators
    attr_reader :pagerduty, :plugin_manager, :current_adapter
    
    def initialize(options)
      @options = options
      @pagerduty = PagerBot::PagerDuty.new(options.fetch(:pagerduty))
      @plugin_manager = PagerBot::PluginManager.new(options[:plugins] || {})
    end

    # Send the parsed query to the correct function/plugin
    # Will return a hash in the following form
    # {
    #   message => "Message to be sent in the channel",
    #   private_message => "Message to be send in pm"
    # }
    def dispatch(parsed_query, event_data)
      @current_adapter = event_data[:adapter]

      # Try to get answer from plugins
      if parsed_query[:plugin]
        begin
          response = plugin_manager.dispatch(
            parsed_query[:plugin], parsed_query, event_data)
        rescue Exception => e
          message = "Hmm, that didn't seem to work: #{e.message}"
          info = PluginManager.info(parsed_query[:plugin])
          if info[:syntax]
            message << "\nSyntax: #{info[:syntax].first}"
          end
          response = {message: message}
        end
      else
        begin
          # Call method on this class by type field indicated by parser output.
          # Note that this wouldn't cause any problems as long as long as
          # parser doesn't output :type => :freeze or similar
          method = parsed_query[:type].gsub(/[- ]/, '_')
          response = self.send method, parsed_query, event_data
        rescue Exception => e
          response = {message: "Hmm, that didn't seem to work: #{e.message}"}
          PagerBot.log.error("Error in dispatch:\n#{e.message}\n#{e.backtrace}")
        end
      end
      response
    end

    +PagerBot::Utilities::DispatchMethod
    def hello(query, event_data={})
      "Hello, #{event_data[:nick]}"
    end

    # because who doesn't like one-liners. Feel free to refactor!
    +PagerBot::Utilities::DispatchMethod
    def list_schedules(query, event_data={})
      msg = "Here are the schedules I know about (schedules in the same line are synonyms):\n" +
        @pagerduty.schedules.list.map { |v| Utilities.pluck('name', v.aliases).sort.join(', ') }.sort.join("\n")
      { private_message: msg }
    end

    +PagerBot::Utilities::DispatchMethod
    def list_people(query, event_data={})
      msg = "Here are the people I know about (people in the same line are synonyms):\n" +
        @pagerduty.users.list.map { |v| Utilities.pluck('name', v.aliases).sort.join(', ') }.sort.join("\n")
      { private_message: msg }
    end

    +PagerBot::Utilities::DispatchMethod
    def manual(query, event_data)
      manual = <<-EOF
I am #{@options[:bot][:name]}. I keep track of the pagers. You can ask me the following:

  *Get command usage:*
    > help

  *Get more detailed command usage:*
    > manual

  *List known schedules:*
    > list

  *List known people:*
    > people

  *Find out who is on call for a schedule:*
    who is on SCHEDULE [at TIME]
    > who is on primary breakage [at 2 pm]

  *Find out when someone is on call:*
    when [am I | is PERSON] on SCHEDULE
    > when am I on triage
    > when is llama on primary breakage
EOF

      plugin_manager.loaded_plugins.each do |name, plugin|
        if plugin.responds_to? :manual
          manual << "\n  *#{plugin.manual.fetch(:description)}*"
          syntax = plugin.manual.fetch(:syntax, []).join("\n    ")
          examples = plugin.manual.fetch(:examples, []).join("\n    > ")
          manual << "\n    #{syntax}"
          manual << "\n    > #{examples}\n"
        end
      end

      { 
        message: "Sending you the manual in a PM.",
        private_message: manual
      }
    end

    +PagerBot::Utilities::DispatchMethod
    def help(query, event_data)
      help = <<-EOF
I am #{@options[:bot][:name]}, and I keep track of the pagers. You can ask me the following:

  manual
  help

  list
  people

  who is on SCHEDULE [at TIME]
  when [am I | is PERSON] on SCHEDULE
EOF
      plugin_manager.loaded_plugins.each do |name, plugin|
        if plugin.responds_to? :manual
          help << "\n  "
          help << plugin.manual.fetch(:syntax).join("\n  ")
        end
      end

      help
    end

    +PagerBot::Utilities::DispatchMethod
    def lookup_time(query, event_data)
      # who is on primary?
      schedule = @pagerduty.find_schedule(query[:schedule])
      time = @pagerduty.parse_time(query[:time], event_data[:nick], :guess => :middle)

      schedule_info = @pagerduty.get(
        "/schedules/#{schedule.id}",
        :params => {
          :since => time.iso8601,
          :until => (time + 1).iso8601
        })

      entries = schedule_info[:schedule][:final_schedule][:rendered_schedule_entries]
      vars = {
        schedule: schedule,
        start: nil
      }
      if entries.length > 0
        oncall = entries.first
        vars[:person] = @pagerduty.users.get(oncall[:user][:id])
        vars[:start] = vars[:person].parse_time(oncall[:start])
      end
      render "lookup_time", vars
    end

    +PagerBot::Utilities::DispatchMethod
    def lookup_person(query, event_data)
      # when am i on primary breakage
      schedule = @pagerduty.find_schedule(query[:schedule])
      person = @pagerduty.find_user(query[:person], event_data[:nick])

      next_oncall = @pagerduty.next_oncall(person.id, schedule.id)

      output_data = {
        time: nil,
        person: person,
        schedule: schedule
      }
      if next_oncall
        output_data[:time] = person.parse_time(next_oncall[:start])
      end

      render "lookup_person", output_data
    end

    +PagerBot::Utilities::DispatchMethod
    def no_such_command(query, event_data)
      "Hmm, I don't understand that command. Maybe you should ask for help?"
    end

    def render(template, variables)
      PagerBot::Template.render(template, variables)
    end
  end
end
