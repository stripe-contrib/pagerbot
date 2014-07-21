require_relative('../../_lib')
require_relative './mocked_pagerduty_class'

class PagerDuty < Critic::MockedPagerDutyTest
  before do
    @pagerduty = PagerBot::PagerDuty.new(@pagerduty_settings)
  end

  describe 'user/schedule collection' do
    it 'should be able to fetch users by id' do
      assert_equal('P123456', @pagerduty.users.get('P123456').id)
      assert_equal('PP1565R', @pagerduty.users.get('PP1565R').id)
    end

    it 'should be able to fetch users by alias' do
      assert_equal('P123456', @pagerduty.users.get('karl').id)
      assert_equal('P123456', @pagerduty.users.get('alias').id)
      assert_equal('PP1565R', @pagerduty.users.get('john').id)
      assert_equal('PP1565R', @pagerduty.users.get('johnsmith').id)
    end

    it 'should fetch timezones' do
      karl = @pagerduty.users.get('P123456')
      john = @pagerduty.users.get('PP1565R')

      assert_equal(0.hours, karl.timezone.utc_offset)
      assert_equal(-5.hours, john.timezone.utc_offset)
    end

    it 'should be able to fetch schedules by alias' do
      assert_equal('PRIMAR1', @pagerduty.schedules.get('primary').id)
    end
  end

  describe 'finding people/schedules' do
    it 'should return user object on find_user' do
      assert_kind_of(PagerBot::Models::User, @pagerduty.find_user('karl'))
      assert_kind_of(PagerBot::Models::User, @pagerduty.find_user('i', 'karl'))
    end
  end
end