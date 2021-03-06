RSpec.describe Mutant::Matcher::Chain do

  let(:object) { described_class.new(matchers) }

  describe '#each' do
    let(:yields) { [] }
    subject { object.each { |entry| yields << entry } }

    let(:matchers) { [matcher_a, matcher_b] }

    let(:matcher_a) { [subject_a] }
    let(:matcher_b) { [subject_b] }

    let(:subject_a) { double('Subject A') }
    let(:subject_b) { double('Subject B') }

    # it_should_behave_like 'an #each method'
    context 'with no block' do
      subject { object.each }

      it { should be_instance_of(to_enum.class) }

      it 'yields the expected values' do
        expect(subject.to_a).to eql(object.to_a)
      end
    end

    it 'should yield subjects' do
      expect { subject }.to change { yields }.from([]).to([subject_a, subject_b])
    end
  end
end
