require "method_decorators"
# Utilities
# Also accessible in templates via helpers.
module PagerBot::Utilities
  # collect a paginated collection from pagerduty
  def self.paginate(endpoint, collection_name, pagerduty=nil)
    pagerduty ||= PagerBot.pagerduty
    offset = 0
    result = {}

    loop do
      resp = pagerduty.get(endpoint, :params => {
        :offset => offset, :limit => 200 })
      resp[collection_name].each do |item|
        result[item[:id]] = item
      end

      offset += resp[collection_name].length
      break if offset >= resp[:total]
    end
    result
  end

  # @param list of hashes [{key: value, ...}, ...]
  # @returns list of values [value, value2, ...]
  def self.pluck(key, list)
    list.map {|el| el[key]}
  end

  # @param list of hashes [{key: value, ...}, ...]
  # @returns hash of lists {value: {key: value}, ...}
  def self.pluck_map(key, list)
    result = {}
    list.each do |value|
      result[value.fetch(key)] = value
    end
    result
  end

  # Take a lists of info we have on users|schedules on
  # pagerduty and database and merge them, adding new
  # users and removing old ones.
  #
  # Detecting that is done by id_value basis.
  #
  # @params [{id: id_value, aliases: [], ...}]
  def self.update_lists(pagerduty_list, database_list)
    pd_ids = pluck_map(:id, pagerduty_list)
    db_ids = pluck_map(:id, database_list)

    to_add_ids = Set.new(pd_ids.keys) - Set.new(db_ids.keys)

    to_add = to_add_ids.to_a.map do |id|
      val = pd_ids[id]
      val["aliases"] ||= []
      val
    end

    to_remove_ids = Set.new(db_ids.keys) - Set.new(pd_ids.keys)
    to_remove = to_remove_ids.to_a.map do |id|
      db_ids[id]
    end

    [to_add, to_remove]
  end

  # Decorator for dispatch methods. Wraps the results in hashes
  # and renders erb templates automatically
  class DispatchMethod < MethodDecorators::Decorator
    def call(wrapped, this, query, event_data, &blk)
      result = wrapped.call(query, event_data, &blk)

      unless result.is_a? Hash
        result = {message: result}
      end
      result.each do |key, value|
        next unless value.is_a? PagerBot::Template::ErbStruct
        adapter = event_data.fetch(:adapter, :irc)
        result[key] = value.render(adapter)
      end
      result
    end
  end


  # removes extra characters that pagerbot doesn't parse
  def self.normalize(text)
    text.gsub(/[^-0-9A-Za-z:+' \/]/, '').downcase
  end

  def self.time_link(time)
    str = time.getutc.strftime("%Y%m%dT%H%M")
    "http://www.timeanddate.com/worldclock/fixedtime.html?iso=#{str}#hg-wc"
  end

  def self.link_to(link, description)
    "<#{link}|#{description}>"
  end

  def self.display_time(time)
    link_to(time_link(time), time.strftime("%l:%M %p %b %e (%z)"))
  end

  def self.display_schedule(schedule, text=nil)
    url = PagerBot.pagerduty.uri_base+"/schedules##{schedule.id}"
    link_to(url, text || schedule.name)
  end
end
