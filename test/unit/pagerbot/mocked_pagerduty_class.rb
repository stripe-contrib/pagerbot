require_relative('../../_lib')

# class to help share some pagerduty stubs/setup between test files
class Critic::MockedPagerDutyTest < Critic::Test
  def fake_user(userinfo={})
    data = {
      time_zone: "Eastern Time (US & Canada)",
      color: "dark-slate-grey",
      email: "bart@example.com",
      avatar_url: "https://secure.gravatar.com/avatar/6e1b6fc29a03fc3c13756bd594e314f7.png?d=mm&r=PG",
      user_url: "/users/PIJ90N7",
      invitation_sent: true,
      role: "admin",
      name: "Bart Simpson"
    }
    data.merge!(userinfo)
    data
  end

  def a(alias_)
    {'name' => alias_}
  end

  before do
    # Put any stubs here that you want to apply globally
    @users = [
      fake_user(id: "P123456", aliases: [a('karl'), a('alias')], 
        time_zone: "GMT+0", name: "Karl-Aksel Puulmann"),
      fake_user(id: "PP1565R", aliases: [a('john'), a('johnsmith')], 
        time_zone: "Eastern Time (US & Canada)",
        name: "John Smith")
    ]

    @schedules = [
      {
        id: "PRIMAR1",
        name: "Primary breakage",
        aliases: [a('primary breakage'), a('primary')]
      },
      {
        id: "PN1D2OC",
        name: "Systems run",
        aliases: [a('sys run'), a('sys')]
      }
    ]

    @pagerduty_settings = {
      api_key: 'fake-api-key',
      subdomain: 'something-reasonable',
      users: @users,
      schedules: @schedules
    }

    @bot_settings = {
      name: 'bot-name'
    }
  end
end