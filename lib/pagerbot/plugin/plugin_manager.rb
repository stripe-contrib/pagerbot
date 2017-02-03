require_relative './plugin_base'

module PagerBot
  class PluginManager
    include SemanticLogger::Loggable

    attr_reader :loaded, :loaded_plugins
    def initialize(configuration)
      reset(configuration)
    end

    def reset(configuration)
      @configuration = configuration
      @loaded_plugins = {}
      @loaded = false
    end

    def load_plugins
      unless @loaded
        @loaded = true
        @configuration.each do |plugin_name, config|
          plugin_name = plugin_name.to_s
          @loaded_plugins[plugin_name] = self.class.load_plugin(plugin_name, config)
        end
      end
    end

    # Try to outsource the parsing to plugins.
    # Done by asking each plugin if they can parse query and returning the
    # first result.
    #
    # This returns false if nothing was found.
    def parse(query)
      @loaded_plugins.each do |plugin_name, plugin|
        next unless plugin.responds_to? :queries
        response = plugin.parse(query)
        if response
          response[:plugin] = plugin_name
          return response
        end
      end
      false
    end

    # Try to answer query by refering to a plugin.
    def dispatch(plugin, query, event_data)
      @loaded_plugins.fetch(plugin).dispatch(query, event_data)
    end

    # look into the plugin folder for plugins that exist
    def self.available_plugins
      files = Dir::glob(File.join(File.dirname(__FILE__), "*.rb"))
      plugins = files.map { |f| File.basename(f, ".rb") }
      plugins.delete("plugin_manager")
      plugins.delete("plugin_base")

      plugins
    end

    def self.info(plugin_name)
      unless available_plugins.include? plugin_name
        raise ArgumentError.new("No plugin named #{plugin_name} found.\n"+
          "Available plugins: #{available_plugins.inspect}")
      end
      class_name = plugin_class plugin_name
      require File.join(File.dirname(__FILE__), plugin_name)
      clazz = class_from_string(class_name)

      ret = {}
      if clazz.responds_to? :manual
        ret = clazz.manual
      end
      ret.merge({
        name: plugin_name,
        description: clazz.description,
        required_fields: clazz.required_fields,
        required_plugins: clazz.required_plugins || []
      })
    end

    def self.load_plugin(plugin_name, config={})
      unless available_plugins.include? plugin_name
        logger.warn "Plugin not listed as available. Skipping.", name: plugin_name, config: config, available_plugins: available_plugins
        return
      end
      class_name = plugin_class plugin_name
      logger.info "Loading plugin.", name: plugin_name, class: class_name, config: config

      require File.join(File.dirname(__FILE__), plugin_name)
      class_from_string(class_name).new(config)
    end

    # Transform plugin_name to PagerBot::Plugins::PluginName
    def self.plugin_class(plugin_name)
      class_name = plugin_name.split("_").map(&:capitalize).join('')
      "PagerBot::Plugins::"+class_name
    end

    def self.class_from_string(str)
      str.split('::').inject(Object) do |mod, class_name|
        mod.const_get(class_name)
      end
    end
  end
end
