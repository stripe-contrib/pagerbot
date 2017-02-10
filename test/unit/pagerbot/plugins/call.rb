require_relative('../../../_lib')

class CallPlugin < Critic::MockedPagerDutyTest
  def parse(text, pm, botname="test-pagerbot")
    PagerBot::Parsing.parse(botname+": "+text, botname, pm)
  end

  before do
    @config = {
      call: {
        keyword: '911',
        email_suffix: "@moon.com"
      },
      email: {
        domain: 'asf',
        api_key: 'fake_key'
      }
    }

    PagerBot.stubs(:pagerduty).returns(@pagerduty)

    @plugin_manager = PagerBot::PluginManager.new(@config)
    @plugin_manager.load_plugins

    am = PagerBot.action_manager({:pagerduty => @pagerduty_settings, :bot => {:name => "pagerbot"}})
    am.stubs(:plugin_manager).returns(@plugin_manager)
  end

  describe "call plugin" do
    it "should call parse on the plugin" do
      got = parse("911 sys everything is on fire", @plugin_manager)
      expected = {team: "sys", plugin: "call", message: "everything is on fire"}
      assert_equal(expected, got)
    end

    it "should call parse on the plugin with a variant of the syntax" do
      got = parse("911 sys subject unicorns are attacking", @plugin_manager)
      expected = {team: "sys", plugin: "call", message: "unicorns are attacking"}
      assert_equal(expected, got)
    end

    it "should consider because the same as subject" do
      got = parse("911 someone else because unicorns are attacking", @plugin_manager)
      expected = {team: "someone else", plugin: "call", message: "unicorns are attacking"}
      assert_equal(expected, got)
    end

    it "should call dispatch on the plugin" do
      query = {team: "sys", plugin: "call", message: "everything is on fire"}

      PagerBot::Plugins::Call.any_instance
        .expects(:dispatch)
        .with(query, {nick: "karl", channel_name: "#channel"})

      PagerBot.action_manager.dispatch query, {nick: "karl", channel_name: "#channel"}
    end

    it "should try to email the team" do
      query = {team: "sys", plugin: "call", message: "everything is on fire"}
      @plugin_manager.loaded_plugins['email']
        .expects(:send_email)
        .with do |email, message, _|
          email == "sys@moon.com" && message == "karl in #channel: #{query[:message]}"
        end

      @plugin_manager.dispatch("call", query, {nick: "karl", channel_name: "#channel"})
    end

    it "should be included in help output" do
      output = PagerBot.action_manager.help({}, {})
      assert_includes(output.fetch(:message), "911 TEAM [MESSAGE]")
    end
  end
end
