RSpec.describe Mutant::Reporter::CLI::Printer::Config do
  setup_shared_context

  def self.it_reports(expected_content)
    it 'writes expected report to output' do
      output = StringIO.new
      described_class.run(output, config)
      output.rewind
      expect(output.read).to eql(strip_indent(expected_content))
    end
  end

  describe '.run' do
    context 'on default config' do
      it_reports(<<-REPORT)
        Mutant configuration:
        Matcher:         #<Mutant::Matcher::Config match_expressions=[] subject_ignores=[] subject_selects=[]>
        Integration:     null
        Expect Coverage: 100.00%
        Jobs:            1
        Includes:        []
        Requires:        []
      REPORT
    end

    context 'with non default coverage expectation' do
      update(:config) { { expected_coverage: 0.1r } }

      it_reports(<<-REPORT)
        Mutant configuration:
        Matcher:         #<Mutant::Matcher::Config match_expressions=[] subject_ignores=[] subject_selects=[]>
        Integration:     null
        Expect Coverage: 10.00%
        Jobs:            1
        Includes:        []
        Requires:        []
      REPORT
    end
  end
end
