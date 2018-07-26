require 'spec_helper'

describe 'Simple tests' do
  context 'Single file test suite, non-concurrent run' do
    let(:result) { run_paraspec_in_fixture('one-file-suite', '-c', '1') }

    it 'succeeds' do
      result.exit_code.should == 0
      result.output.should include('3 examples, 0 failures')
    end
  end

  context 'with custom formatter' do
    let(:result) { run_paraspec_in_fixture('one-file-suite', '-c', '1', '--', '-fd') }

    it 'works' do
      result.exit_code.should == 0
      result.output.should include('3 examples, 0 failures')
    end

    it 'runs tests with custom formatter' do
      result.exit_code.should == 0
      result.output.should include('is beautiful two')
    end
  end
end
