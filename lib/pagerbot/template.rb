require 'ostruct'

module PagerBot::Template
  class ErbStruct
    def initialize(template_name, hash)
      @_template_name = template_name
      hash.each do |key, value|
        singleton_class.send(:define_method, key) { value }
      end 
    end

    def render(adapter=nil)
      template_name = @_template_name
      unless adapter.nil?
        template_name << "_" + adapter.to_s
      end
      template = PagerBot::Template.fetch_template(template_name)
      # '>' denotes that erb should trim some whitespace
      ERB.new(template, nil, '>').result(binding).strip
    end

    def utilities
      PagerBot::Utilities
    end
  end

  @@cache = {}
  def self.fetch_template(template_name)
    return @@cache[template_name] unless @@cache[template_name].nil?

    templates_dir = File.expand_path(
      File.join(File.dirname(__FILE__), "../../templates"))

    template_file_list = Dir.entries(templates_dir)
    PagerBot.log.debug("Template files: #{template_file_list}")

    file_path = File.join(templates_dir, template_name+".erb")

    @@cache[template_name] = File.read(file_path)
  end

  def self.render(template_name, variables={})
    ErbStruct.new(template_name, variables)
  end
end
