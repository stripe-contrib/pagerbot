module PagerBot::Parsing
  def self.strip_name(text, nick=nil)
    text.gsub(/\A(@?#{nick}:?) /, '')
  end

  def self.split_text(text)
    command, *words = PagerBot::Utilities.normalize(text).split
    [command, words]
  end

  def self.parse(text, botname, plugin_manager = nil)
    text = strip_name(text, botname)
    # TODO: this isn't a very good approach and would break with unicode names 
    # note that this somewhat breaks some messages, stripping them of
    # symbols and downcasing everything.
    command, words = split_text(text)

    case command
    when 'debug'
      {type: 'debug'}
    when 'list'
      {type: 'list-schedules'}
    when 'people'
      {type: 'list-people'}
    when 'who', 'whos', "who's"
      # type: lookup-time
      parse_lookup_schedule_by_time(words)
    when 'when', 'whens', "when's"
      # type: lookup-person
      parse_lookup_schedule_by_person(words)
    when 'hi', 'hello', 'hey'
      {type: 'hello'}
    when 'manual'
      {type: 'manual'}
    when 'help'
      {type: 'help'}
    else
      info = {text: text, command: command, words: words}
      if plugin_manager.nil?
        plugin_manager = PagerBot.plugin_manager
      end
      plugins_response = plugin_manager.parse(info)
      return plugins_response if plugins_response
      {type: 'no such command'}
    end
  end

  def self.parse_lookup_schedule_by_time(words)
    # who is on primary breakage

    schedule = []
    time = []
    parse_stage = nil

    words.each do |word|
      case word
      when 'on'
        if parse_stage == :schedule
          parse_stage = :time
        else
          parse_stage = :schedule
        end
      when 'at', 'now'
        parse_stage = :time
      when 'in'
        parse_stage = :time
        time << word
      else
        schedule << word if parse_stage == :schedule
        time << word if parse_stage == :time
      end
    end

    # TODO: restore easter egg
    #if schedule == ['first']
    #  return {:schedule => :first}
    #end

    if (time.empty?) 
      time = ['now']
    end

    {
      type: 'lookup-time',
      schedule: schedule.join(' '),
      time: time.join(' ')
    }
  end

  def self.parse_lookup_schedule_by_person(words)
    # when am i on primary breakage

    person = []
    schedule = []
    parse_stage = nil

    words.each do |word|
      case word
      when 'is', 'am', 'are'
        parse_stage = :person
      when 'on'
        parse_stage = :schedule
      else
        person << word if parse_stage == :person
        schedule << word if parse_stage == :schedule
      end
    end

    {
      type: 'lookup-person',
      person: person.join(' '),
      schedule: schedule.join(' ')
    }
  end
end
