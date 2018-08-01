require 'spec_helper'
require 'nokogiri'

describe 'Integration tests' do
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

    context 'with state debug logging' do
      let(:result) { run_paraspec_in_fixture('one-file-suite',
        '-d', 'state', '-c', '2') }

      it 'works' do
        result.exit_code.should == 0
        result.output.should include('5 examples, 0 failures')
      end

      it 'runs tests in two workers' do
        result.exit_code.should == 0
        result.errput.should include('[w1] [state] Got spec')
        result.errput.should include('[w1] [state] Finished running spec')
        result.errput.should include('[w2] [state] Got spec')
        result.errput.should include('[w2] [state] Finished running spec')
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

  context 'pending example' do
    let(:result) { run_paraspec_in_fixture('pending-example', '-c', '1') }

    it 'succeeds' do
      result.exit_code.should == 0
      result.output.should include('1 example, 0 failures, 1 pending')
    end
  end

  context 'failing example' do
    let(:result) { run_paraspec_in_fixture('failing-example', '-c', '1') }

    it 'fails' do
      result.exit_code.should == 1
      result.output.should include('1 example, 1 failure')
    end
  end

  context 'test suite uses junit formatter' do
    context 'successful test suite' do
      let(:result) { run_paraspec_in_fixture('junit-formatter-successful', '-c', '1', '--', '-fd') }

      it 'succeeds' do
        result.exit_code.should == 0
        result.output.should include('2 examples, 0 failures, 1 pending')
      end
    end

    context 'failing test suite' do
      let(:result) { run_paraspec_in_fixture('junit-formatter', '-c', '1', '--', '-fd') }

      it 'fails' do
        result.exit_code.should == 1
        result.output.should include('4 examples, 1 failure, 2 pending')
      end
    end

    context 'concurrent run' do
      let(:result) { run_paraspec_in_fixture('junit-formatter-concurrent', '-c', '2', '--') }

      let(:tmp_dir_path) { File.join(File.dirname(__FILE__), '..', 'fixtures', 'junit-formatter-concurrent', 'tmp') }

      before do
        FileUtils.rm_rf(tmp_dir_path)
      end

      it 'succeeds' do
        result.exit_code.should == 0
      end

      it 'creates one junit xml output file' do
        result
        File.exist?(File.join(tmp_dir_path, 'rspec.xml')).should be true
        File.exist?(File.join(tmp_dir_path, 'rspec1.xml')).should be false
        File.exist?(File.join(tmp_dir_path, 'rspec2.xml')).should be false
      end

      it 'merges all results into one junit xml output file' do
        result
        doc = Nokogiri::HTML(File.read(File.join(tmp_dir_path, 'rspec.xml')))
        doc.xpath('//testcase').count.should == 3
      end
    end
  end

  context 'conditionals on groups and examples' do
    context 'evaluating to true' do
      let(:result) { run_paraspec_in_fixture('conditional-met', '-c', '1', '--', '-fd') }

      it 'reports same counts as rspec' do
        result.exit_code.should == 0
        result.output.should include('2 examples, 0 failures')
      end
    end

    context 'evaluating to false' do
      let(:result) { run_paraspec_in_fixture('conditional-unmet', '-c', '1', '--', '-fd') }

      it 'reports same counts as rspec' do
        result.exit_code.should == 0
        result.output.should include('1 example, 0 failures')
      end
    end
  end

  context 'shared examples in another file' do
    let(:result) { run_paraspec_in_fixture('shared-examples', '-c', '1', '--', '-fd') }

    it 'succeeds' do
      result.exit_code.should == 0
      result.output.should include('1 example, 0 failures')
    end
  end

  context 'hooks' do
    let(:result) { run_paraspec_in_fixture('hooks', '-c', '1', '--', '-fd') }

    it 'succeeds' do
      result.exit_code.should == 0
      result.output.should include('1 example, 0 failures')
    end

    it 'runs each describe hooks' do
      result.exit_code.should == 0
      result.output.should include('before each describe')
      result.output.should include('after each describe')
    end

    it 'runs all describe hooks' do
      result.exit_code.should == 0
      result.output.should include('before all describe')
      result.output.should include('after all describe')
    end

    it 'runs each shared context hooks' do
      result.exit_code.should == 0
      result.output.should include('before each shared context')
      result.output.should include('after each shared context')
    end

    it 'runs all shared context hooks' do
      result.exit_code.should == 0
      result.output.should include('before all shared context')
      result.output.should include('after all shared context')
    end
  end
end
