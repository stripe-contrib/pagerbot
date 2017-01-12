module PagerBot::Plugins
  class ScheduleOverride
    include PagerBot::PluginBase
    responds_to :queries, :manual
    description "Put person on call for for a while."

    def initialize(config={})
    end

    def self.manual
      {
        description: "Put someone on call",
        syntax: [
          "put PERSON on SCHEDULE [at START] for DURATION",
          "put PERSON on SCHEDULE [from START] until END"
        ],
        examples: [
          "put me on primary breakage from 2 pm until 9 pm",
          "put jonathan on triage on September 27th 2 pm for 4 hours",
          "put ray on run for 30 minutes"
        ]
      }
    end

    def parse(query)
      # put me on primary breakage from 2 pm until 9 pm
      return unless ['put', 'override'].include? query[:command]

      parse_stage = :person
      parse_vars = {
        to: [],
        for: [],
        from: [],
        schedule: [],
        person: [],
      }

      query[:words].each do |word|
        case word
        when 'on'
          if parse_stage == :schedule
            parse_stage = :from
          else
            parse_stage = :schedule
          end
        when 'from', 'at'
          parse_stage = :from
        when 'to', 'until'
          parse_stage = :to
        when 'for'
          parse_stage = :for
        else
          parse_vars[parse_stage] << word
        end
      end

      if !parse_vars[:to].empty? && !parse_vars[:for].empty?
        raise RuntimeError.new("Can't specify both 'to' and 'for'")
      elsif parse_vars[:to].empty? && parse_vars[:for].empty?
        #raise RuntimeError.new("Must specify either 'to' or 'for'")
        # probably meant for another plugin
        return
      end

      if parse_vars[:from].empty?
        parse_vars[:from] = ['now']
      end
      result = {
        person: parse_vars[:person].join(' '),
        schedule: parse_vars[:schedule].join(' '),
        from: parse_vars[:from].join(' '),
      }
      if (!parse_vars[:to].empty?)
        result[:to] = parse_vars[:to].join(' ')
      else
        result[:for] = parse_vars[:for].join(' ')
      end
      result
    end

    +PagerBot::Utilities::DispatchMethod
    def dispatch(query, event_data)
      # put me on primary breakage from 2 pm until 9 pm
      asker = pagerduty.find_user(event_data[:nick])
      person = pagerduty.find_user(query[:person], event_data[:nick])
      from = asker.parse_time(query[:from])

      if query[:to]
        to = asker.parse_time(query[:to])
      else
        duration = ChronicDuration.parse(query[:for], :keep_zero => true)
        raise "Failed to parse duration from `#{query[:for]}`." if duration == 0
        to = from + duration
        log.debug("Duration is #{duration}, from is #{from}, to is #{to}")
      end

      if from >= to
        raise RuntimeError.new("Your date range seems to be backwards.\n#{from} is after #{to}")
      end

      schedule = pagerduty.find_schedule(query[:schedule])

      override = pagerduty.post(
        "/schedules/#{schedule.id}/overrides",
        {
          :override => {
            :start => from.iso8601,
            :end => to.iso8601,
            :user => {
              :id => person.id.to_s,
              :type => :user_reference
            }
          }
        },
        :content_type => :json)

      vars = {
        person: person,
        from: asker.parse_time(override[:override][:start]),
        to: asker.parse_time(override[:override][:end]),
        schedule: schedule
      }

      render "schedule_override", vars
    end
  end
end
