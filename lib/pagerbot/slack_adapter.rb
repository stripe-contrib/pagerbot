# slack webhook-using integration for pagerbot

require 'json'
require 'sinatra/base'
require 'rest-client'

module PagerBot
  class SlackAdapter < Sinatra::Base
    include SemanticLogger::Loggable

    def emoji
      configatron.bot.slack.emoji || ":frog:"
    end

    def send_private_message(message, user_id)
      request = {
        username: configatron.bot.name,
        icon_emoji: emoji,
        text: message,
        channel: user_id,
        token: configatron.bot.slack.api_token
      }
      logger.info "Sending private message.", request.except(:token, :icon_emoji)
      RestClient.post "https://slack.com/api/chat.postMessage", request
    end

    def make_reply(answer, event_data)
      if answer[:private_message]
        send_private_message(answer[:private_message], event_data[:user_id])
      end

      unless answer[:message]
        return ""
      end

      JSON.generate({
        username: configatron.bot.name,
        icon_emoji: emoji,
        text: answer[:message]
      })
    end

    def event_data(request)
      {
        nick: request[:user_name],
        channel_name: request[:channel_name],
        text: request[:text],
        user_id: request[:user_id],
        adapter: :slack
      }
    end

    post '/' do
      if configatron.bot.slack.webhook_token
        return "" unless request[:token] == configatron.bot.slack.webhook_token
      end
      unless configatron.bot.all_channels ||
             configatron.bot.channels.include?(request[:channel_name])
        return ""
      end
      text = PagerBot::Parsing.strip_names(params[:text], [configatron.bot.name])
      return "" if text.nil?

      request_data = event_data request
      answer = PagerBot.process(request_data[:text], request_data)
      logger.info "Received a query:", request_data, answer: answer
      make_reply answer, request_data
    end

    get '/ping' do
      'pong'
    end
  end
end
