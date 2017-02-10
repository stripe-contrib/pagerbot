module PagerBot
  # This module should be included by all plugins
  module PluginBase
    module ClassMethods
      attr_reader :actions_responding_to, :required_plugins

      # Actions to listen to. Plugins should call this with :query
      # after including this module
      def responds_to(*actions)
        @actions_responding_to = actions
      end

      def responds_to?(action)
        (self.actions_responding_to || []).include? action
      end

      def requires_plugins(*plugins)
        @required_plugins = plugins
      end

      def description(value=nil)
        if value.nil?
          return @description || ""
        end
        @description = value
      end

      def required_fields(*fields)
        if fields.empty?
          return @required_fields || []
        end
        @required_fields = fields
      end
    end

    # render from template file
    def render(template, variables)
      PagerBot::Template.render(template, variables)
    end

    def pagerduty
      PagerBot.pagerduty
    end

    def get_plugin(name)
      plugin = PagerBot.plugin_manager.loaded_plugins[name]
      if plugin.nil?
        raise RuntimeError.new(
          "Plugin #{name} is not loaded. Please check config.rb and update config.local.rb.")
      end
      plugin
    end

    def join_all(hash)
      hash.each do |key, value|
        if value.is_a? Array
          hash[key] = value.join(' ')
        end
      end
    end

    def log
      PagerBot.log
    end

    def manual
      self.class.manual
    end

    # Example: plugin.responds_to? manual
    def responds_to?(action)
      self.class.responds_to?  action
    end

    # add classmethods when included
    def self.included(by)
      by.extend MethodDecorators
      by.extend ClassMethods
    end
  end
end
