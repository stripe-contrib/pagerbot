# irc integration for pagerbot

require 'cinch'

module PagerBot::IrcAdapter
  class PagerDutyPlugin
    include Cinch::Plugin
    listen_to :channel

    # hack to support empty lines in irc
    def pad(message)
      message.gsub(/^$/, " ")
    end

    def event_data(m)
      {
        nick: m.user.nick,
        channel_name: m.channel.name,
        text: m.message,
        adapter: :irc
      }
    end

    def reply(m, answer)
      if answer[:private_message]
        m.user.send(pad(answer[:private_message]))
      end
      if answer[:message]
        m.reply(pad(answer[:message]))
      end
    end

    def listen(m)
      return unless m.message.start_with? m.bot.nick+":"
      params = event_data(m)
      reply(m, PagerBot.process(params[:text], params))
    end
  end

  def self.run!
    bot = Cinch::Bot.new do
      configure do |c|
        c.nick = configatron.bot.name
        c.password = configatron.bot.irc.fetch(:bot_password, nil) 
        c.server = configatron.bot.irc.server
        c.ssl.use = configatron.bot.irc.fetch(:use_ssl, false)
        # add a hash at the beginning if needed
        c.channels = configatron.bot.channels.map do |ch|
          ch.start_with?("#") ? ch : "#"+ch
        end
        c.plugins.plugins = [PagerDutyPlugin]
        puts c
      end
    end

    bot.start
  end
end
