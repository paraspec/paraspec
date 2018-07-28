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

    context 'with debug logging' do
      let(:result) { run_paraspec_in_fixture('one-file-suite',
        '-d', '-c', '2') }

      it 'works' do
        result.exit_code.should == 0
        result.output.should include('5 examples, 0 failures')
      end

      it 'runs tests in two workers' do
        result.exit_code.should == 0
        result.errput.should include('[w1] Got spec')
        result.errput.should include('[w1] Finished running spec')
        result.errput.should include('[w2] Got spec')
        result.errput.should include('[w2] Finished running spec')
      end
    end
  end

  context 'error outside examples' do
    let(:result) { run_paraspec_in_fixture('error-outside-examples', '-c', '1') }

    it 'fails' do
      result.exit_code.should > 0
      # We load the examples, hence the example count is greater than zero here
      result.output.should include('1 example, 0 failures, 1 error occurred outside of examples')
    end
  end

  context 'syntax error outside examples' do
    let(:result) { run_paraspec_in_fixture('syntax-error-outside-examples', '-c', '1') }

    it 'fails' do
      result.exit_code.should > 0
      result.output.should include('0 examples, 0 failures, 1 error occurred outside of examples')
    end
  end
end
