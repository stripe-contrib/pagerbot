require_relative('../../../_lib')

class ScheduleOverridePlugin < Critic::MockedPagerDutyTest
  def check_parse(text, expected, botname="test-pagerbot")
    got = PagerBot::Parsing.parse(botname+": "+text, botname, @plugin_manager)
    assert_equal(expected, got)
  end

  def check_parse_fails(text)
    text = PagerBot::Utilities.normalize(text)
    command, *words = text.split
    assert_nil(@plugin.parse({command: command, words:words}))
  end

  before do
    @plugin_manager = PagerBot::PluginManager.new(:schedule_override => {})
    @plugin_manager.load_plugins
    @plugin = @plugin_manager.loaded_plugins.fetch('schedule_override')

    @pagerduty = PagerBot::PagerDuty.new(@pagerduty_settings)
    PagerBot.stubs(:pagerduty).returns(@pagerduty)
  end

  describe "override schedule plugin" do
    describe "parsing" do
      it "[put|override] PERSON on SCHEDULE ..." do
        ["put", "override"].each do |word|
          check_parse("#{word} me on primary breakage from now for 3 hours",
            {
              plugin: 'schedule_override', person: 'me', schedule: 'primary breakage',
              from: 'now', for: '3 hours'
            })
          check_parse("#{word} me on primary breakage from now for 3.5 hours",
            {
              plugin: 'schedule_override', person: 'me', schedule: 'primary breakage',
              from: 'now', for: '3.5 hours'
            })
          check_parse("#{word} Jake on triage until 3 PM",
            {
              plugin: 'schedule_override', person: 'jake', schedule: 'triage',
              from: 'now', to: '3 pm'
            })

          check_parse("#{word} karl on triage at 6 PM to 2 AM",
            {
              plugin: 'schedule_override', person: 'karl', schedule: 'triage',
              from: '6 pm', to: '2 am'
            })
        end
      end

      it "should skip parsing the rest" do
        check_parse_fails("manual")
        check_parse_fails("who is on primary")
      end

      it "should skip parsing switch_shift queries" do
        check_parse_fails("put me on primary during nel's shift on 5th of August")
      end
    end

    describe "dispatch" do
      it "should successfully go through the happy path" do
        PagerBot.pagerduty
          .expects(:post)
          .with { |url, _, _| url == '/schedules/PRIMAR1/overrides' }
          .returns({
            override: {
              id: "PRIMAR1",
              user: {
                name: "Karl-Aksel Puulmann",
                id: "P123456"
              },
              end: "2014-07-29T03:09:21Z",
              start: "2014-07-29T01:09:21Z"
            }
          })

        query = {
          person: "karl",
          schedule: "primary",
          from: "now",
          for: "2 hours"
        }
        val = @plugin_manager.dispatch(
          "schedule_override", query, {nick: "karl"})
        expected = "Ok. Put Karl-Aksel Puulmann on Primary breakage from 2014-07-29 01:09:21 +0000 until 2014-07-29 03:09:21 +0000"
        assert_equal(expected, val.fetch(:message))
      end

      it "should use the asking person's timezone when interpreting times" do
        PagerBot.pagerduty
          .expects(:post)
          .with { |_, params, _| params[:override][:start] == '2016-01-01T12:00:00-05:00' }
          .returns({
            # Not used by the test, it's just here so the code doesn't blow up.
            override: {
              id: "PRIMAR1",
              user: {
                name: "Karl-Aksel Puulmann",
                id: "P123456"
              },
              start: "2016-01-01T01:00:00Z",
              end: "2016-01-01T03:00:00Z"
            }
          })

        query = {
          person: "karl",
          schedule: "primary",
          from: "2016-01-01 at 12:00",
          for: "2 hours"
        }
        @plugin_manager.dispatch("schedule_override", query, {nick: "john"})
      end
    end
  end
end
