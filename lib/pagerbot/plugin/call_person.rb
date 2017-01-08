module PagerBot::Plugins
  class CallPerson
    include PagerBot::PluginBase
    responds_to :queries, :manual
    description "Page a person by nick or schedule. Needs a scratch schedule, escalation policy, and service."
    required_fields "schedule_id", "service_id"

    def initialize(config)
      @schedule_id = config.fetch(:schedule_id)
      @service_id = config.fetch(:service_id)
      @service = pagerduty.get("/services/#{@service_id}?include%5B%5D=integrations")[:service]
    end

    def self.manual
      {
        description: "Page a person by nick or schedule (which could be a team)",
        syntax: ["get PERSON|SCHEDULE [SUBJECT]"],
        examples: [
          "get karl you are needed in warroom",
          "get myschedule the load balancers are down"
        ]
      }
    end

    def parse(query)
      return unless query[:command] == "get"

      to = []
      subject = []
      implicit_subject = (query[:words] & ['subject', 'because']).empty?

      parse_stage = :to
      query[:words].each do |word|
        case word
        when 'subject', 'because'
          parse_stage = :subject
        else
          case parse_stage
          when :to
            to << word
            if implicit_subject
              parse_stage = :subject
            end
          when :subject then subject << word
          end
        end
      end
      {
        to: to.join(" "),
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
      # hacky flow since API doesn't support creating an incident directly
      # against a user:
      # - put person on call on schedule for 5 minutes
      # - trigger incident
      person_name, person_uid = person(query[:to], event_data[:nick])
      log.info("Found #{person_name} #{person_uid}")

      start = Time.now()
      # People still get pinged even if they're not on call,
      # so this is a safety measure.
      to = start + ChronicDuration.parse("5 minutes")

      override = pagerduty.post(
        "/schedules/#{@schedule_id}/overrides",
        {
          :override => {
            :start => start.iso8601,
            :end => to.iso8601,
            :user => {
              :id => person_uid.to_s,
              :type => :user_reference
            }
          }
        },
        :content_type => :json
      )

      log.info "Put #{person_name} on temporary schedule for 5 minutes. #{override}"

      incident = post_incident(
        # :TODO: Frail.
        :service_key => @service[:integrations][0][:integration_key],
        :event_type => :trigger,
        :description => query[:subject]
      )

      log.info "Created incident for #{person_name}. #{incident.inspect}"
      # RAGE: Of course incident doesn't include the id of the incident created.
      service_url = "#{pagerduty.uri_base}/services/#{@service[:id]}"

      render "call_person", {person_name: person_name, service_url: service_url}
    end

    def person(nick_or_schedule, requestor)
      begin
        person = pagerduty.find_user(nick_or_schedule, requestor)
        return person.name, person.id
      rescue Pagerbot::UserNotFoundError
        log.info("Didn't find person '#{nick_or_schedule}'. Looking via schedule.")
        schedule = pagerduty.find_schedule(nick_or_schedule)
        if schedule.nil?
          raise RuntimeError.new(
            "Couldn't find a person or schedule named '#{nick_or_schedule}'")
        end
        users = pagerduty.get_schedule_oncall(schedule.id, Time.now())
        if users.length == 0
          raise RuntimeError.new("No one is on call for #{nick_or_schedule}")
        end
        return users[0][:summary], users[0][:id]
      end
    end
  end
end
