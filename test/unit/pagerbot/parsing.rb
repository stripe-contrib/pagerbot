require_relative('../../_lib')

class Parsing < Critic::Test
  def parse(text, botname="test-pagerbot")
    PagerBot::Parsing.parse(text, botname)
  end

  def check_parse(text, hash)
    assert_equal(hash, parse("test-pagerbot: "+text))
  end

  describe 'Parsing expressions' do
    # follow the order, examples in manual
    it "help" do
      check_parse('help', {type: 'help'})
    end

    it "manual" do
      check_parse('manual', {type: 'manual'})
    end

    it "people" do
      check_parse('people', {type: 'list-people'})
    end

    it "list" do
      check_parse('list', {type: 'list-schedules'})
    end

    it "hi" do
      ['hello', 'hi', 'hey'].each do |word|
        check_parse(word, {type: 'hello'})
      end
    end

    it "[who|whos] is on SCHEDULE [at TIME]" do
      ["who", "whos"].each do |word|
        check_parse("#{word} is on triage?",
          {type: 'lookup-time', schedule: 'triage', time: 'now'})
        check_parse("#{word} is on primary breakage now?",
          {type: 'lookup-time', schedule: 'primary breakage', time: 'now'})
        check_parse("#{word} is on triage at 3 AM?",
          {type: 'lookup-time', schedule: 'triage', time: '3 am'})
      end
    end

    it "[when|whens] [am I | is PERSON] on SCHEDULE" do
      ["when", "whens"].each do |word|
        check_parse("#{word} am I on triage",
          {type: 'lookup-person', person: 'i', schedule: 'triage'})
        check_parse("#{word} is Jake on primary breakage?",
          {type: 'lookup-person', person: 'jake', schedule: 'primary breakage'})
      end
    end
  end

  def strip_name(text, botname="test-pagerbot")
    PagerBot::Parsing.strip_name(text, botname)
  end

  describe 'Parsing botname' do
    #Three types of syntax are currently supported:
    it "test-pagerbot:" do
      assert_equal('make me a sandwich',
                   strip_name('test-pagerbot: make me a sandwich'))
    end

    it "@test-pagerbot:" do
      assert_equal('make me a sandwich',
                   strip_name('@test-pagerbot: make me a sandwich'))
    end

    it "@test-pagerbot" do
      assert_equal('make me a sandwich',
                   strip_name('@test-pagerbot make me a sandwich'))
    end

    it "test-pagerbot" do
      assert_equal('make me a sandwich',
                   strip_name('test-pagerbot make me a sandwich'))
    end
  end
end
