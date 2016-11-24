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
        expected = {to: "karl", subject: "you are needed in warroom"}
        assert_equal(expected, got)
      end

      it 'should consider because the same as subject' do
        got = plugin.parse({
          command: "get",
          words: "someone else because you are needed in warroom".split
        })
        expected = {to: "someone else", subject: "you are needed in warroom"}
        assert_equal(expected, got)
      end

      it 'should still parse query when an explicit "subject"/"because" prefix is not present' do
        got = plugin.parse({
          command: "get",
          words: "karl you are needed in warroom".split
        })
        expected = {to: "karl", subject: "you are needed in warroom"}
        assert_equal(expected, got)
      end
    end

    describe 'dispatch' do
      it 'should not error with standard responses' do
        plug = plugin # just load it once

        PagerBot::PagerDuty.any_instance
          .expects(:post)
          .with { |url, params, _|
            url == "/schedules/PFAKESCHED/overrides" &&
            params[:override][:user][:id] == "P123456"
          }
          .returns({})

        plug
          .expects(:post_incident)
          .with({
            :event_type => :trigger,
            :service_key => "fake_service_key",
            :description => "there's not enough pizza"
          })

        answer = plug.dispatch({
          to: "me", subject: "there's not enough pizza"
        }, {nick: "karl"}).fetch(:message)
        assert_includes(answer, "Contacted Karl-Aksel Puulmann, see ")
        assert_includes(answer, "pagerduty.com/services/PFAKESRV")
      end

      it "should look up by schedule if a person isn't found" do
        plug = plugin # just load it once

        mock_sched = Object.new()
        mock_sched.stubs(:id).returns('SCHED123')
        PagerBot::PagerDuty.any_instance
          .expects(:find_schedule)
          .with { |name| name == 'sre' }
          .returns(mock_sched)

        PagerBot::PagerDuty.any_instance
          .expects(:get_schedule_oncall)
          .with { |schedule_id, _, _| schedule_id == 'SCHED123' }
          .returns([{id: 'P123456', name: 'Bob'}])

        PagerBot::PagerDuty.any_instance
          .expects(:post)
          .with { |url, params, _|
            url == "/schedules/PFAKESCHED/overrides" &&
            params[:override][:user_id] == "P123456"
          }
          .returns({})

        plug
          .expects(:post_incident)
          .with({
            :event_type => "trigger",
            :service_key => "fake_service_key",
            :description => "there's too much pizza"
          })

        answer = plug.dispatch({
          to: "sre", subject: "there's too much pizza"
        }, {nick: "karl"}).fetch(:message)
        assert_includes(answer, "Contacted Bob, see ")
        assert_includes(answer, "pagerduty.com/services/PFAKESRV")
      end

      it "should return a userful error if no one's on call for the schedule" do
        mock_sched = Object.new()
        mock_sched.stubs(:id).returns('SCHED123')
        PagerBot::PagerDuty.any_instance
          .expects(:find_schedule)
          .with { |name| name == 'sre' }
          .returns(mock_sched)

        PagerBot::PagerDuty.any_instance
          .expects(:get_schedule_oncall)
          .with { |schedule_id, _, _| schedule_id == 'SCHED123' }
          .returns([])

        begin
          plugin.dispatch({
            to: "sre", subject: "the system is down, down down down down"
          }, {nick: "karl"}).fetch(:message)
        rescue => e
          assert_includes(e.to_s, "No one is on call for sre")
        else
          assert(false, "Shouldn't get here.")
        end
      end

      it 'should return a useful error if neither person nor schedule is found' do
        PagerBot::PagerDuty.any_instance
          .expects(:find_schedule)
          .with { |name| name == "schedule-that-doesn't-exist" }
          .returns(nil)

        begin
          plugin.dispatch({
            to: "schedule-that-doesn't-exist",
            subject: "the system is down, down down down down"
          }, {nick: "karl"}).fetch(:message)
        rescue => e
          assert_includes(e.to_s, "Couldn't find a person or schedule")
        else
          assert(false, "Shouldn't get here.")
        end
      end
    end
  end
end
