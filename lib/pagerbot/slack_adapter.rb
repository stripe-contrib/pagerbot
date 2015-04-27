# slack webhook-using integration for pagerbot

require 'json'
require 'sinatra/base'
require 'rest-client'

module PagerBot
  class SlackAdapter < Sinatra::Base
    def emoji
      configatron.bot.slack.emoji || ":frog:"
    end

    def send_private_message(message, user_id)
      data = {
        username: configatron.bot.name,
        icon_emoji: emoji,
        text: message,
        channel: user_id,
        token: configatron.bot.slack.api_token
      }
      PagerBot.log.info(data.inspect)

      resp = RestClient.post "https://slack.com/api/chat.postMessage", data
      PagerBot.log.info resp
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
        token: request[:token],
        nick: request[:user_name],
        channel_name: request[:channel_name],
        text: request[:text],
        user_id: request[:user_id],
        adapter: :slack
      }
    end

    post '/' do
      PagerBot.log.info event_data(request)
      if configatron.bot.slack.webhook_token
        return "" unless request[:token] == configatron.bot.slack.webhook_token
      end
      unless configatron.bot.all_channels ||
             configatron.bot.channels.include?(request[:channel_name])
        return ""
      end
      return "" unless request[:text].match(%r{@?#{configatron.bot.name}[: ]})

      params = event_data request
      answer = PagerBot.process(params[:text], params)
      make_reply answer, params
    end

    get '/ping' do
      'pong'
    end
  end
end
