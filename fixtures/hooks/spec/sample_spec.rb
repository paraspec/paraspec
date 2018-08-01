shared_context 'shared context hooks' do
  before(:all) do
    puts "before all shared context"
  end

  before(:each) do
    puts "before each shared context"
  end

  after(:each) do
    puts "after each shared context"
  end

  after(:all) do
    puts "after all shared context"
  end
end

describe 'Sample' do
  include_context 'shared context hooks'

  before(:all) do
    puts "before all describe"
  end

  before(:each) do
    puts "before each describe"
  end

  it 'succeeds' do
    puts "the test"
  end

  after(:each) do
    puts "after each describe"
  end

  after(:all) do
    puts "after all describe"
  end
end
