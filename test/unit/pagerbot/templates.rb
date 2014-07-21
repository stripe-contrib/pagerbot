require_relative('../../_lib')

class Templates < Critic::Test
  describe 'Template rendering' do
    before do
      @filepath = File.expand_path(File.join(
        __FILE__,
        "../../../../templates/_test_sample_template.erb"))
      File.open(@filepath, 'w') do |file|
        file.write("Testing, <%= variable %>!")
      end
    end

    after do
      File.delete(@filepath)
    end

    it 'should render with fake file' do
      got = PagerBot::Template.render("_test_sample_template", {
        variable: 'testing'
      }).render
      assert_equal("Testing, testing!", got)
    end

    it 'should raise an error if variable not given' do
      assert_raises(NameError) do
        PagerBot::Template.render("_test_sample_template", {}).render
      end
    end
  end
end
