module PagerBot::Plugins
  class CallPerson
    include PagerBot::PluginBase
    responds_to :queries, :manual
    description "Send a page directly to a person."
    required_fields "schedule_id", "service_id"

    def initialize(config)
      @schedule_id = config.fetch(:schedule_id)
      @service_id = config.fetch(:service_id)
      @service = pagerduty.get("/services/#{@service_id}")[:service]
    end

    def self.manual
      {
        description: "Trigger a call to a person",
        syntax: ["get PERSON [subject SUBJECT]"],
        examples: ["get karl subject you are needed in warroom"]
      }
    end

    def parse(query)
      # get karl because everything is on fire
      return unless query[:command] == "get"

      person = []
      subject = []

      parse_stage = :person
      query[:words].each do |word|
        case word
        when 'subject', 'because'
          parse_stage = :subject
        else
          case parse_stage
          when :person then person << word
          when :subject then subject << word
          end
        end
      end
      {
        person: person.join(" "),
        subject: subject.join(" ")
      }
    end

    # might be moves to pagerduty class later
    def post_incident(payload)
      begin
        payload_json = JSON.dump(payload)
        resp = pagerduty.incidents_api.post(payload_json, :content_type => :json)
        answer = JSON.parse(resp, :symbolize_names => true)
        log.debug("POST to incidents, payload=#{payload.inspect}, response=#{answer}")
        answer
      rescue Exception => e
        log.error("Failed to post to incident API: #{payload.inspect}."+
          "\nError: #{e.message}")
        raise RuntimeError.new("Problem talking to PagerDuty incidents:"+
          " #{e.message}\nRequest was #{payload.inspect}")
      end
    end

    +PagerBot::Utilities::DispatchMethod
    def dispatch(query, event_data)
      # hacky flow since API doesn't support creating an incident directly against a user
      # - put person on call on schedule for 3 minutes
      # - trigger incident
      person = pagerduty.find_user(query[:person], event_data[:nick])
      start = person.parse_time("now")
      # People still get pinged even if they're not on call,
      # so this is a safety measure.
      to = start + ChronicDuration.parse("5 minutes")
      
      override = pagerduty.post(
        "/schedules/#{@schedule_id}/overrides",
        {
          :override => {
            :start => start.iso8601,
            :end => to.iso8601,
            :user_id => person.id.to_s
          }
        },
        :content_type => :json
      )

      log.info "Put #{person.name} on temporary schedule for 5 minutes. #{override}"

      incident = post_incident(
        :service_key => @service[:service_key],
        :event_type => "trigger",
        :description => query[:subject]
      )

      log.info "Created incident for #{person.name}. #{incident.inspect}"
      # RAGE: Of course incident doesn't include the id of the incident created.
      service_url = "#{pagerduty.uri_base}#{@service[:service_url]}"

      render "call_person", {person: person, service_url: service_url}
    end
  end
end
