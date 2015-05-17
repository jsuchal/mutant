RSpec.describe Mutant::Reporter::CLI do
  setup_shared_context

  let(:object) { described_class.new(output, format) }
  let(:output) { StringIO.new                        }

  let(:tput) do
    double(
      'tput',
      restore: '[tput-restore]',
      prepare: '[tput-prepare]'
    )
  end

  let(:framed_format) do
    described_class::Format::Framed.new(
      tty:  false,
      tput: tput
    )
  end

  let(:progressive_format) do
    described_class::Format::Progressive.new(tty: false)
  end

  let(:format) { framed_format }

  def contents
    output.rewind
    output.read
  end

  def self.it_reports(expected_content)
    it 'writes expected report to output' do
      expect(subject).to be(object)
      expect(contents).to eql(strip_indent(expected_content))
    end
  end

  before do
    allow(Time).to receive(:now).and_return(Time.now)
  end

  describe '.build' do
    subject { described_class.build(output) }

    let(:progressive_format) do
      described_class::Format::Progressive.new(tty: tty?)
    end

    let(:framed_format) do
      described_class::Format::Framed.new(
        tty:  true,
        tput: tput
      )
    end

    before do
      expect(ENV).to receive(:key?).with('CI').and_return(ci?)
    end

    let(:output) { double('Output', tty?: tty?) }
    let(:tty?)   { true                         }
    let(:ci?)    { false                        }

    context 'when not on CI and on a tty' do
      before do
        expect(described_class::Tput).to receive(:detect).and_return(tput)
      end

      context 'and tput is available' do
        it { should eql(described_class.new(output, framed_format)) }
      end

      context 'and tput is not available' do
        let(:tput) { nil }

        it { should eql(described_class.new(output, progressive_format)) }
      end
    end

    context 'when on CI' do
      let(:ci?) { true }
      it { should eql(described_class.new(output, progressive_format)) }
    end

    context 'when output is not a tty?' do
      let(:tty?) { false }
      it { should eql(described_class.new(output, progressive_format)) }
    end

    context 'when output does not respond to #tty?' do
      let(:output) { double('Output') }
      let(:tty?)   { false }

      it { should eql(described_class.new(output, progressive_format)) }
    end
  end

  describe '#warn' do
    subject { object.warn(message) }

    let(:message) { 'message' }

    it_reports("message\n")
  end

  describe '#delay' do
    subject { object.delay }

    it { should eql(0.05) }
  end

  describe '#start' do
    subject { object.start(env) }

    context 'on progressive format' do
      let(:format) { progressive_format }

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
      let(:format) { progressive_format }
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

    context 'on framed format' do
      it_reports '[tput-prepare]'
    end
  end

  describe '#progress' do
    subject { object.progress(status) }

    context 'on progressive format' do
      let(:format) { progressive_format }

      context 'with empty scheduler' do
        update(:env_result) { { subject_results: [] } }

        it_reports "(00/02)   0% - killtime: 0.00s runtime: 4.00s overhead: 4.00s\n"
      end

      context 'with last mutation present' do
        update(:env_result) { { subject_results: [subject_a_result] } }

        context 'when mutation is successful' do
          it_reports "(02/02) 100% - killtime: 2.00s runtime: 4.00s overhead: 2.00s\n"
        end

        context 'when mutation is NOT successful' do
          update(:mutation_a_test_result) { { passed: true } }
          it_reports "(01/02)  50% - killtime: 2.00s runtime: 4.00s overhead: 2.00s\n"
        end
      end
    end

  end
end
