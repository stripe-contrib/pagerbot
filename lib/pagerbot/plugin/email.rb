require 'mailgun'

module PagerBot::Plugins
  # Plugin which other plugins can use to send email
  class Email
    include PagerBot::PluginBase

    description "Mailgun email plugin."
    required_fields "api_key", "domain"

    def initialize(config)
      @mailgun = Mailgun::Client.new config.fetch(:api_key)
      @mailgun_domain = config.fetch(:domain)
    end

    def send_email(to, subject, text)
      message_params = {
        from: "pagerbot@#{@mailgun_domain}",
        to: to,
        subject: subject,
        text: text
      }
      @mailgun.send_message @mailgun_domain, message_params
    end
  end
end
