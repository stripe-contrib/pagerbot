require_relative('../../../_lib')

class AddAlias < Critic::MockedPagerDutyTest
  before do
    @plugin = PagerBot::PluginManager.load_plugin "add_alias", {}
  end

  describe 'Adding an alias to user or schedule' do
    describe 'parsing' do
      it 'should parse a simple example' do
        got = @plugin.parse({
          command: "alias",
          words: "karl@mycompany.com as the  best-karl".split
        })
        assert_equal got, {
          searched_alias: 'karl@mycompany.com',
          new_alias: 'the best-karl'
        }
      end
    end

    describe 'matching' do
      it 'should match on id, name, email by default if they are present' do
        assert_equal @plugin.matches_in([name: 'foo'], 'foo'), [name: 'foo']
        assert_equal @plugin.matches_in([name: 'foobar'], 'foo'), []
        assert_equal @plugin.matches_in([], 'aaa'), []
        assert_equal @plugin.matches_in([{}], 'aaa'), []
        assert_equal @plugin.matches_in([name: nil], 'aaa'), []
        assert_equal @plugin.matches_in([email: 'foo'], 'foo'), [email: 'foo']
        assert_equal @plugin.matches_in([id: 'foo'], 'foo'), [id: 'foo']
      end
    end
  end
end
