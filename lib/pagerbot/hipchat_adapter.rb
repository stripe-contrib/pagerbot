# HipChat add-on for pagerbot

require 'json'
require 'sinatra/base'
require 'rest-client'

require_relative './datastore'

module PagerBot
  class HipchatAdapter < Sinatra::Base
    def db
      store.db
    end

    def store
      @store ||= PagerBot::DataStore.new
    end

    def base_url(request)
      "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
    end

    get '/' do
      content_type :json
      {
        "vendor" => {
          "url" => "https://github.com/stripe/pagerbot",
          "name" => "Stripe"
        },
        "name" => "Pagerbot",
        "key" => "com.pagerbot.addon",
        "links" => {
          "self" => base_url(request)
        },
        "capabilities" => {
          "webhook" => [{
            "url" => base_url(request) + "/webhook",
            "event" => "room_message",
            "pattern" => "^#{configatron.bot.name}"
          }],
          "hipchatApiConsumer" => {
            "scopes" => [
              "send_notification",
              "send_message"
            ],
            "fromName" => configatron.bot.name
          },
          "installable" => {
            "allowGlobal" => true,
            "allowRoom" => false,
            "callbackUrl" => base_url(request) + "/get_oauth_credentials"
          }
        },
        "description" => "Manage Pagerduty on-call schedules from within HipChat"
      }.to_json
    end

    def request_access_token
      url = "https://#{configatron.bot.hipchat.oauthId}:#{configatron.bot.hipchat.oauthSecret}" \
            "@api.hipchat.com/v2/oauth/token"
      PagerBot.log.info "Requesting a HipChat access token."
      data = {
        "grant_type" => "client_credentials",
        "scope" => "send_message send_notification"
      }
      begin
        response = RestClient.post url, data.to_json, :content_type => :json
      rescue => e
        PagerBot.log.info e.inspect
      end
      response = JSON.parse(response.body)
      configatron.bot.hipchat.accessToken = response["access_token"]
      configatron.bot.hipchat.accessToken_expiresIn = response["expires_in"]
      configatron.bot.hipchat.accessToken_createdAt = Time.now()

      configatron.bot.hipchat.accessToken
    end

    # https://www.hipchat.com/docs/apiv2/auth#oauth_urls
    def get_access_token(force=false)
      if not configatron.bot.hipchat.has_key?(:accessToken) or force
        request_access_token
      else
        expires_in = configatron.bot.hipchat.accessToken_expiresIn
        created_at = configatron.bot.hipchat.accessToken_createdAt
        if (Time.now() - created_at) > expires_in
          request_access_token
        else
          configatron.bot.hipchat.accessToken
        end
      end
    end

    post '/get_oauth_credentials' do
      request_json = JSON.parse request.body.read
      configatron.bot.hipchat.oauthId = request_json["oauthId"]
      configatron.bot.hipchat.oauthSecret = request_json["oauthSecret"]

      db['bot'].update({}, {
        "$set" => {
          "hipchat.oauthId" => configatron.bot.hipchat.oauthId,
          "hipchat.oauthSecret" => configatron.bot.hipchat.oauthSecret
        }
      }, :upsert => true)
      get_access_token(true)
    end

    def get_request_data(request_json)
      {
        event: request_json["event"],
        nick: request_json["item"]["message"]["from"]["mention_name"],
        room_name: request_json["item"]["room"]["name"],
        text: request_json["item"]["message"]["message"],
        message_id: request_json["item"]["message"]["id"],
        user_id: request_json["item"]["message"]["from"]["id"],
        adapter: :hipchat
      }
    end

    post '/webhook' do
      request_data = get_request_data JSON.parse request.body.read
      PagerBot.log.info request_data
      return "" unless request_data[:event] == "room_message"
      return "" unless request_data[:text].start_with?(configatron.bot.name+":")
      return "" unless configatron.bot.channels.include? request_data[:room_name]

      answer = PagerBot.process(request_data[:text], request_data)
      make_reply answer, request_data
    end

    delete '/webhook/:id' do
      if params[:id] == configatron.bot.hipchat.oauthId
        db['bot'].update({}, {
          "$unset" => {
            "hipchat.oauthId" => "",
            "hipchat.oauthSecret" => ""
          }
        }, :upsert => true)
      end
      PagerBot.log.info "HipChat add-on uninstalled."
    end

    get '/ping' do
      'pong'
    end

    def make_reply(answer, request_data)
      if answer[:private_message]
        # This should be uncommented once HipChat adds support for 1:1 messaging for addons
        # send_private_message(answer[:private_message], request_data[:user_id])
        #
        # For now, we're sending a public message to the room.
        send_message(answer[:private_message], request_data)
      end

      unless answer[:message]
        return ""
      end
      send_message(answer[:message], request_data)
    end

    def send_private_message(message, user_id)
      data = {
        message: message,
      }
      url = "https://api.hipchat.com/v2/user/#{user_id}/message"
      send_hipchat_request(data, url)
    end

    def send_message(message, request_data)
      data = {
        message: message,
        message_format: "text"
      }
      url = "https://api.hipchat.com/v2/room/#{request_data[:room_name]}/notification"
      send_hipchat_request(data, url)
    end

    def send_hipchat_request(data, url)
      PagerBot.log.info(data.inspect)
      params = {:auth_token => get_access_token()}
      begin
        resp = RestClient.post(
          url,
          data.to_json,
          :content_type => :json,
          :params => params
        )
      rescue => e
        PagerBot.log.info e.inspect
        raise e
      end
      PagerBot.log.info resp
    end

  end
end
