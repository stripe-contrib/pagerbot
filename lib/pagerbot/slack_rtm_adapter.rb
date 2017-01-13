require 'json'
require 'sinatra/base'
require 'slack-ruby-client'

module PagerBot
  class SlackRTMAdapter
    def self.run!
      PagerBot::SlackRTMAdapter.new().run!
    end

    def self.can_connect?(token)
      return false unless token
      Slack.configure do |config|
        config.token = token
      end
      begin
        client = Slack::Web::Client.new
        client.auth_test
        true
      rescue
        false
      end
    end

    def initialize
      # Load slack API token
      Slack.configure do |config|
        config.token = configatron.bot.slack.api_token
      end
      @client = Slack::RealTime::Client.new
      @user_cache = {}
    end

    def run!
      @client.on :message do |data|
        if data.type == 'message'
          if data.subtype == 'message_changed'
            data.message.channel = data.channel
            data = data.message
          end
          process_message(data)
        end
      end
      @client.start!
    end

    def find_user(user_id)
      @user_cache[user_id] ||= @client.users.fetch(user_id)
      @user_cache[user_id]
    end

    def process_message(message)
      # Ignore messages from bots and self.
      return if message.subtype == 'bot_message'
      return if message.user == @client.self.id

      extra_data = {
        nick: find_user(message.user).name,
        adapter: :slack
      }

      usernames = [@client.self.name, "<@#{@client.self.id}>"]
      # In direct messages, don't require the bot name.
      if message.channel.start_with? 'D'
        usernames.push nil
      end

      text = PagerBot::Parsing.strip_names message.text, usernames
      return if text.nil? # Not addressed to this user.

      response = PagerBot.process text, extra_data
      if response[:private_message]
        dm_channel = "@#{find_user(message.user).name}"
        send_message response.fetch(:private_message), dm_channel
      else
        send_message response.fetch(:message), message.channel
      end
    end

    def send_message(message, channel)
      @client.web_client.chat_postMessage channel: channel, text: message, as_user: true, unfurl_links: false
    end
  end
end
