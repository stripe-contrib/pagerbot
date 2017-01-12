require_relative('../../../_lib')
require 'json'

class CallPerson < Critic::MockedPagerDutyTest
  def plugin
    config = { service_id: "PFAKESRV", schedule_id: "PFAKESCHED"}
    PagerBot::PluginManager.load_plugin "call_person", config
  end

  before do
    @service = {
      id: "PFAKESRV",
      name: "Fake service",
      integrations: [{
        id: "PFAKEINTEGRATION",
        integration_key: "fake_service_key",
      }]
    }

    @pagerduty = PagerBot::PagerDuty.new(@pagerduty_settings)
    PagerBot.stubs(:pagerduty).returns(@pagerduty)
    PagerBot::PagerDuty.any_instance
      .stubs(:get)
      .with("/services/PFAKESRV?include%5B%5D=integrations")
      .returns(:service => @service)
  end

  describe 'Alerting people directly plugin' do
    describe 'parse' do
      it 'should ignore other queries' do
        assert_nil(plugin.parse({command: "xxx"}))
      end

      it 'should parse query in example' do
        got = plugin.parse({
          command: "get",
          words: "karl subject you are needed in warroom".split
        })
        expected = {person: "karl", subject: "you are needed in warroom"}
        assert_equal(expected, got)
      end

      it 'should consider because the same as subject' do
        got = plugin.parse({
          command: "get",
          words: "someone else because you are needed in warroom".split
        })
        expected = {person: "someone else", subject: "you are needed in warroom"}
        assert_equal(expected, got)
      end

      it 'should still parse query when an explicit "subject"/"because" prefix is not present' do
        got = plugin.parse({
          command: "get",
          words: "karl you are needed in warroom".split
        })
        expected = {person: "karl", subject: "you are needed in warroom"}
        assert_equal(expected, got)
      end

    end

    describe 'dispatch' do
      before do
        PagerBot::PagerDuty.any_instance
          .expects(:post)
          .with { |url, params, _|
            url == "/schedules/PFAKESCHED/overrides" &&
            params[:override][:user][:id] == "P123456"
          }
          .returns({})

        @plugin = plugin
        @plugin
          .expects(:post_incident)
          .with({
            :event_type => :trigger,
            :service_key => "fake_service_key",
            :description => "description description"
          })
      end

      it 'should not error with standard responses' do
        answer = @plugin.dispatch({
          person: "me", subject: "description description"
        }, {nick: "karl"}).fetch(:message)
        assert_includes(answer, "Contacted Karl-Aksel Puulmann, see ")
        assert_includes(answer, "pagerduty.com/services/PFAKESRV")
      end
    end
  end
end
