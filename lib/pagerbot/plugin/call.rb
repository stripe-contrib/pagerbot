module PagerBot::Plugins
  # Example plugin which sends an email to a team on command
  class Call
    include PagerBot::PluginBase
    responds_to :queries, :manual
    # todo: add functionality which deals with this.
    description "Send an email to a team on command. Requires email plugin to be enabled."
    required_fields 'email_suffix'
    requires_plugins 'email'

    def initialize(config)
      @email_suffix = config.fetch(:email_suffix)
    end

    # What is shown about this command in help and manual
    def self.manual
      {
        description: "Trigger an email to team#{@email_suffix}",
        syntax: ["911 TEAM [MESSAGE]"],
        examples: [
          "911 my-team",
          "911 sys our mongos need scaling"
        ]
      }
    end

    def parse(query)
      # <'911'> TEAM [MESSAGE]
      return unless query[:command] == '911'

      team = []
      message = []
      implicit_subject = (query[:words] & ['subject', 'because']).empty?

      parse_stage = :team
      query[:words].each do |word|
        case word
        when 'subject', 'because'
          parse_stage = :message
        else
          case parse_stage
          when :team
            team << word
            if  implicit_subject
              parse_stage = :message
            end
          when :message then message << word
          end
        end
      end
      {
        team: team.join(" "),
        message: message.join(" ")
      }
    end

    +PagerBot::Utilities::DispatchMethod
    def dispatch(query, event_data)
      email = query[:team] + @email_suffix
      subject = "#{event_data[:nick]} in #{event_data[:channel_name]}: #{query[:message]}"
      body = 'Created by pagerbot at ' + Time.now.to_s

      log.info("Sending email to #{email}, message: #{subject}")
      get_plugin('email').send_email(email, subject, body)

      "Queued email to #{email.inspect}."
    end
  end
end
