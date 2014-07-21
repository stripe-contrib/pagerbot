require_relative('../../../_lib')

class SwitchShiftPlugin < Critic::MockedPagerDutyTest
  def check_parse(text, expected, botname="test-pagerbot")
    got = PagerBot::Parsing.parse(botname+": "+text, botname, @plugin_manager)
    assert_equal(expected, got)
  end

  def check_parse_fails(text)
    command, *words = PagerBot::Utilities.normalize(text).split
    assert_nil(@plugin.parse({command: command, words:words}))
  end

  def expect_override(start_date, end_date, override={:override => {:user => {:name => ""}}})
    @pagerduty
      .expects(:post)
      .with do |url, data, _|
        assert_equal(start_date, data[:override][:start])
        url == "/schedules/PRIMAR1/overrides" &&
        data[:override][:start] == start_date &&
        data[:override][:end] == end_date &&
        data[:override][:user_id] == "P123456"
      end
      .returns(override)
  end

  def expect_entries(range_start, range_end, entries)
    response = {
      total: entries.length,
      entries: entries
    }
    @pagerduty
      .expects(:get)
      .with do |url, data, _|
        url == "/schedules/PRIMAR1/entries" &&
        data[:params][:since] == range_start &&
        data[:params][:until] == range_end
      end
      .returns(response)
  end

  before do
    @plugin_manager = PagerBot::PluginManager.new(:switch_shift => {})
    @plugin_manager.load_plugins
    @plugin = @plugin_manager.loaded_plugins.fetch('switch_shift')

    @pagerduty = PagerBot::PagerDuty.new(@pagerduty_settings)
    PagerBot.stubs(:pagerduty).returns(@pagerduty)
  end

  describe "switch shift plugin" do
    describe "parsing" do
      it "put PERSON on SCHEDULE during PERSON's shift on DATE" do
        check_parse("put karl on primary during john's shift on August 24th",
          {
            plugin: "switch_shift", person: "karl", whose_shift: "john",
            day: "august 24th", schedule: "primary"
          })
      end

      it "should skip parsing the rest" do
        check_parse_fails("manual")
        check_parse_fails("who is on primary")
      end

      it "should skip parsing switch_shift queries" do
        check_parse_fails("put karl on primary for 3 hours")
      end
    end

    describe "dispatch" do
      it "should successfully go through the happy path" do
        expect_entries("2010-08-05T00:00:00-04:00", "2010-08-05T23:59:59-04:00", [
          { user: { id: "SOMETHINGELSE"} },
          {
            start: "2010-08-05T07:30:00-04:00",
            end: "2010-08-05T20:55:00-04:00",
            user: {
              id: "PP1565R",
              name: "John Smith"
            }
          },
          { user: { id: "ANOTHERFAKE"} },
        ])

        query = {
          person: "karl", whose_shift: "john",
          day: "August 5th 2010", schedule: "primary"
        }
        expect_override("2010-08-05T07:30:00-04:00", "2010-08-05T20:55:00-04:00")

        val = @plugin_manager.dispatch("switch_shift", query, {nick: "john"})
        assert_equal(
          "Ok, put Karl-Aksel Puulmann on Primary breakage from 2010-08-05 07:30:00 -0400 to 2010-08-05 20:55:00 -0400.",
          val[:message])
      end
    end

    it "should give an error reason when person is not on schedule that day" do
      expect_entries("2010-08-05T00:00:00-04:00", "2010-08-05T23:59:59-04:00", [
        { user: { id: "SOMEONEELSE"} }])
      query = {
        person: "karl", whose_shift: "john",
        day: "August 5th 2010", schedule: "primary"
      }

      val = @plugin_manager.dispatch("switch_shift", query, {nick: "john"})
      assert_equal(
        "Sorry, but John Smith is not on schedule on 2010-08-05.",
        val[:message])
    end

    it "should give an error reason when person is on schedule multiple times that day" do
      expect_entries("2010-08-05T00:00:00-04:00", "2010-08-05T23:59:59-04:00", [
        { user: { id: "PP1565R"} },
        { user: { id: "PP1565R"} }])
      query = {
        person: "karl", whose_shift: "john",
        day: "August 5th 2010", schedule: "primary"
      }

      val = @plugin_manager.dispatch("switch_shift", query, {nick: "john"})
      assert_equal(
        "Sorry, but John Smith is on call multiple times on 2010-08-05.",
        val[:message])
    end
  end
end
