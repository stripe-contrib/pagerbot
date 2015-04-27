module PagerBot::Plugins
  class SwitchShift
    include PagerBot::PluginBase
    responds_to :queries, :manual
    description "Take over someone's on-call shift"

    def initialize(config={})
    end

    def self.manual
      {
        description: "Take over someone's shift",
        syntax: [
          "put PERSON on SCHEDULE during ANOTHERPERSON's shift on DAY"
        ],
        examples: [
          "put me on primary during llama's shift August 8th"
        ]
      }
    end

    def parse(query)
      # put me on schedule during C's shift on tuesday
      return unless query[:command] == 'put'

      parse_stage = :person
      parse_vars = {
        person: [],
        whose_shift: [],
        schedule: [],
        day: []
      }

      query[:words].each do |word|
        case word
        when 'on'
          if [:whose_shift, :day].include? parse_stage
            parse_stage = :day
          else
            parse_stage = :schedule
          end
        when 'during', 'taking'
          parse_stage = :whose_shift
        when 'shift'
          parse_stage = :day
        else
          parse_vars[parse_stage] << word
        end
      end

      return if [:whose_shift, :schedule].any? {|p| parse_vars[p].empty?}

      if parse_vars[:day].empty?
        parse_vars[:day] = ['today']
      end
      
      # TODO: check the 's of person
      result = Hash[ parse_vars.map { |k, v| [k, v.join(' ')] } ]
      result[:whose_shift] = result[:whose_shift].chomp "'s"
      result
    end

    # return hash
    # {
    #   failure_reason: nil OR symbol,
    #   start: TIME, # missing if fail
    #   end: TIME, # missing if fail
    # }
    def when_oncall(person_id, schedule_id, range_start, range_end, asker)
      entries = pagerduty.get(
        "/schedules/#{schedule_id}/entries",
        params: {
          since: range_start.iso8601,
          until: range_end.iso8601,
          overflow: true
        })
      oncall = entries[:entries].select do |p| 
        p[:user][:id] == person_id.to_s
      end

      result = { :fail_reason => nil }

      if oncall.length == 0
        result[:fail_reason] = :not_on_call
      elsif oncall.length > 1
        result[:fail_reason] = :on_call_multiple_times
      else
        result[:oncall] = oncall.first
        result[:from] = pagerduty.parse_time(oncall.first[:start], asker)
        result[:to] = pagerduty.parse_time(oncall.first[:end], asker)
        result[:shift_person] = oncall.first[:user][:name]
      end
      result
    end

    +PagerBot::Utilities::DispatchMethod
    def dispatch(query, event_data)
      person = pagerduty.find_user(
        query[:person], event_data[:nick])
      shift_person = pagerduty.find_user(
        query[:whose_shift], event_data[:nick])

      schedule = pagerduty.find_schedule(query[:schedule])
      day_start, day_end = day_range(shift_person.parse_time(query[:day]))

      oncall = when_oncall(
        shift_person.id, schedule.id,
        day_start, day_end, 
        event_data[:nick])

      vars = {
        day: day_start,
        schedule: schedule,
        person: person,
        shift_person: shift_person,
      }
      vars.merge!(oncall)

      unless vars[:fail_reason]
        pagerduty.post(
          "/schedules/#{schedule.id}/overrides",
          {
            :override => {
              :start => vars[:from].iso8601,
              :end => vars[:to].iso8601,
              :user_id => person.id.to_s
            }
          },
          :content_type => :json)
      end

      render "switch_shift", vars
    end

    private
    def day_range(t)
      start = Time.new(t.year, t.month, t.day, 00, 00, 00, t.utc_offset)
      end_ = Time.new(t.year, t.month, t.day, 23, 59, 59, t.utc_offset)
      [start, end_]
    end
  end
end
