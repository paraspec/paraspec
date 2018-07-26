require 'spec_helper'

describe 'Simple tests' do
  context 'with concurrency 1' do
    context 'single file test suite' do
      let(:result) { run_paraspec_in_fixture('one-file-suite', '-c', '1') }

      it 'succeeds' do
        result.exit_code.should == 0
        result.output.should include('5 examples, 0 failures')
      end

      it 'queues examples independently' do
        result.exit_code.should == 0
        result.output.should include('2 example groups queued')
      end
    end

    context 'with custom formatter' do
      let(:result) { run_paraspec_in_fixture('one-file-suite', '-c', '1', '--', '-fd') }

      it 'works' do
        result.exit_code.should == 0
        result.output.should include('5 examples, 0 failures')
      end

      it 'runs tests with custom formatter' do
        result.exit_code.should == 0
        result.output.should include('is beautiful two')
      end
    end
  end

  context 'with concurrency 2' do
    context 'single file test suite' do
      let(:result) { run_paraspec_in_fixture('one-file-suite', '-c', '2') }

      it 'succeeds' do
        result.exit_code.should == 0
        result.output.should include('5 examples, 0 failures')
      end

      it 'queues examples independently' do
        result.exit_code.should == 0
        result.output.should include('2 example groups queued')
      end
    end

    context 'with custom formatter' do
      let(:result) { run_paraspec_in_fixture('one-file-suite', '-c', '2', '--', '-fd') }

      it 'works' do
        result.exit_code.should == 0
        result.output.should include('5 examples, 0 failures')
      end

      it 'runs tests with custom formatter' do
        result.exit_code.should == 0
        result.output.should include('is beautiful two')
      end
    end
  end
end
