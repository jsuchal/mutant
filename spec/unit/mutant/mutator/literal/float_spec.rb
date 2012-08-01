require 'spec_helper'

describe Mutant::Mutator::Literal, 'float' do
  let(:source) { '10.0' }

  let(:mutations) do
    mutations = []
    mutations << 'nil'
    mutations << '0.0'
    mutations << '1.0'
    mutations << random_float.to_s
    mutations << '0.0/0.0'
    mutations << '1.0/0.0'
    mutations << [:negate, [:call, [:lit, 1.0], :/, [:arglist, [:lit, 0.0]]]]
    mutations << [:lit, -10.0]
  end

  let(:random_float) { 7.123 }

  before do
    Mutant::Random.stub(:float => random_float)
  end

  it_should_behave_like 'a mutator'
end
