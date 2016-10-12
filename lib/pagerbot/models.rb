require 'ostruct'
require 'set'
require 'active_support/core_ext/hash/indifferent_access'

module PagerBot
  module Models
    class Collection
      attr_reader :list

      def initialize(list, model_class=nil)
        @list = list
        unless model_class.nil?
          @list = @list.map {|el| model_class.new(el)}
        end
        index!
      end

      def get(index_field_value)
        @index[normalize(index_field_value)]
      end

      def ambiguous_aliases
        seen = Set.new
        ambiguous = Set.new
        @list.each do |member|
          member.aliases.each do |alias_|
            norm_alias = normalize(alias_['name'])
            if seen.include?(norm_alias)
              ambiguous << norm_alias
            end
            seen << norm_alias
          end
        end
        ambiguous
      end

      def serializable_list
        @list.map { |member| member.to_h }
      end

      private
      def normalize(string)
        PagerBot::Utilities.normalize(string.to_s)
      end

      def index!
        @index = {}
        ambiguous = ambiguous_aliases
        unless ambiguous.empty?
          PagerBot.log.warn(
            "Skipping the following ambiguous aliases: #{ambiguous.to_a}")
        end

        @list.each do |member|
          add_index(member.id, member)

          # add email as an index for users
          if member.is_a?(User)
            norm_email = member.email.split('@').first
            if has_index?(norm_email)
              PagerBot.log.warn("Adding ambiguous email alias: #{norm_email} for #{member.email}")
            end
            add_index(norm_email, member)
          end

          member.aliases = member.aliases.select do |alias_|
            norm_alias = normalize(alias_['name'])
            unless ambiguous.include? norm_alias
              add_index(norm_alias, member)
              true
            end
          end
        end
      end

      def add_index(key, value)
        @index[normalize(key)] = value
      end

      def has_index?(key)
        @index.key?(normalize(key))
      end
    end

    class ModelBase < OpenStruct
      def initialize(hash)
        hash = hash.with_indifferent_access
        hash.delete('_id')
        hash['aliases'] ||= []
        marshal_load hash
      end

      def to_json
        table.to_json
      end

      def to_h
        table
      end

      def [](key)
        table[key]
      end

      def []=(key, value)
        table[key] = value
      end

      def normalized(key)
        PagerBot::Utilities.normalize(self[key])
      end

      # def matches(query)
      #   is_match = true
      #   query.each do |key, expected|
      #     is_match = is_match && self[key] == expected
      #   end
      #   is_match
      # end
    end

    # Constructed from pagerduty response + aliases
    #
    # {
    #   time_zone: "Eastern Time (US & Canada)",
    #   color: "dark-slate-grey",
    #   email: "bart@example.com",
    #   avatar_url: "https://secure.gravatar.com/avatar/6e1b6fc29a03fc3c13756bd594e314f7.png?d=mm&r=PG",
    #   user_url: "/users/PIJ90N7",
    #   invitation_sent: true,
    #   role: "admin",
    #   name: "Bart Simpson",
    #   aliases: ["alias1", "alias2"]
    # }
    class User < ModelBase
      def parse_time(time, extra_args={})
        Chronic.time_class = timezone
        extra_args[:guess] ||= :begin
        parsed_time = Chronic.parse(time, extra_args)
        raise RuntimeError.new("I don't understand time #{time.inspect}") unless parsed_time
        parsed_time
      end

      def timezone
        if time_zone
          return ActiveSupport::TimeZone[time_zone]
        else
          log.warn "Unable to find timezone for #{person}; falling back to my local time"
          return Time
        end
      end
    end

    # Constructed from pagerduty response + aliases
    #
    # {
    #   id: "PRIMAR1",
    #   name: "Primary",
    #   time_zone: "Eastern Time (US & Canada)",
    #   today: "2013-03-26",
    #   escalation_policies: [{
    #     name: "Another Escalation Policy",
    #     id: "P08G4S6"
    #   }],
    #   aliases: ["primary", "another"]
    # }
    class Schedule < ModelBase; end
  end
end
