module PagerBot; end

require 'configatron'
require 'semantic_logger'

require_relative './pagerbot/utilities'
require_relative './pagerbot/template'
require_relative './pagerbot/datastore'
require_relative './pagerbot/errors'
require_relative './pagerbot/pagerduty'
require_relative './pagerbot/parsing'
require_relative './pagerbot/action_manager'
require_relative './pagerbot/slack_adapter'
require_relative './pagerbot/slack_rtm_adapter'
require_relative './pagerbot/hipchat_adapter'
require_relative './pagerbot/irc_adapter'
require_relative './pagerbot/plugin/plugin_manager'

module PagerBot
  def self.action_manager(config = nil)
    config ||= configatron.to_h
    @action_manager ||= PagerBot::ActionManager.new config
  end

  def self.plugin_manager
    action_manager.plugin_manager
  end

  def self.pagerduty
    action_manager.pagerduty
  end

  # Process the message, returning a string on what to respond and performs the
  # action indicated.
  def self.process(message, extra_info={})
    plugin_manager.load_plugins

    bot_name = extra_info.fetch :bot_name, configatron.bot.name
    log.info "msg=#{message.inspect}, extra_info=#{extra_info.inspect}"
    query = PagerBot::Parsing.parse(message, bot_name)
    log.info "query=#{query.inspect}"
    answer = action_manager.dispatch(query, extra_info)
    log.info "answer=#{answer.inspect}"
    answer
  end

  def self.log
    return @logger unless @logger.nil?
    @logger = SemanticLogger['PagerBot']
    @logger
  end

  # Load configuration saved into the database by AdminPage
  # into configatron, also adding schedules and users.
  def self.load_configuration_from_db!
    store = DataStore.new
    settings = {}
    # load pagerduty settings
    settings[:pagerduty] = store.get_or_create('pagerduty')
    settings[:bot] = store.get_or_create('bot')
    settings[:plugins] = {}

    plugins = store.db_get_list_of('plugins')
    plugins.each do |plugin|
      next unless plugin[:enabled]
      settings[:plugins][plugin["name"]] = plugin["settings"]
    end

    settings[:pagerduty][:users] = store.db_get_list_of('users')
    settings[:pagerduty][:schedules] = store.db_get_list_of('schedules')
    configatron.configure_from_hash(settings)
  end

  def self.reload_configuration!
    @action_manager = nil
    # this will recreate the action_manager
    load_configuration_from_db!
    PagerBot.plugin_manager.load_plugins
  end
end

if __FILE__ == $0
  require_relative './admin/admin_server'
  def to_boolean(s)
    !!(s =~ /^(true|t|yes|y|1)$/i)
  end

  is_admin = ARGV.first == 'admin'
  is_admin ||= ARGV.first == 'web' && !to_boolean(ENV['DEPLOYED'] || "")

  SemanticLogger.default_level = ENV.fetch('LOG_LEVEL', 'info').downcase
  SemanticLogger.add_appender(io: STDERR, formatter: :color)

  if is_admin
    PagerBot::AdminPage.run!
  else
    PagerBot.reload_configuration!
    PagerBot.log.info("Starting application", is_admin: is_admin, adapter: configatron.bot.adapter, argv: ARGV)

    if ARGV.include?('web') || ['slack', 'hipchat'].include?(configatron.bot.adapter)
      if ARGV.include?('slack') || configatron.bot.adapter == 'slack'
        PagerBot::SlackAdapter.run!
      elsif ARGV.include?('hipchat') || configatron.bot.adapter == 'hipchat'
        PagerBot::HipchatAdapter.run!
      end
    elsif ARGV.include?('slack-rtm') || configatron.bot.adapter == 'slack-rtm'
      PagerBot::SlackRTMAdapter.run!
    elsif ARGV.include?('irc') || configatron.bot.adapter == 'irc'
      PagerBot::IrcAdapter.run!
    else
      desiredAdapter = ARGV.first || configatron.bot.adapter
      PagerBot.log.error("Could not find adapter #{desiredAdapter}.\n" \
        "It must be one of 'irc', 'slack', 'slack-rtm' or 'hipchat'.\n\n" \
        "To configure the bot, run this command again with `admin` as the first argument.")
      exit 1
    end
  end
end
