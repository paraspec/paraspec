shared_context 'shared context hooks' do
  before(:all) do
    @shared_all = 'shared_all'
  end

  before(:each) do
    @shared_each = 'shared_each'
  end

  after(:each) do
    expect(@shared_each).to eq('shared_each')
    expect(@shared_all).to eq('shared_all')
  end

  after(:all) do
    expect(@shared_all).to eq('shared_all')
  end
end

describe 'Sample' do
  include_context 'shared context hooks'

  before(:all) do
    @all = 'all'
  end

  before(:each) do
    @each = 'each'
  end

  context 'one context' do
    10.times do |i|
      it "succeeds #{i} time" do
        expect(@each).to eq('each')
        expect(@all).to eq('all')

        expect(@shared_each).to eq('shared_each')
        expect(@shared_all).to eq('shared_all')
      end

      context 'subcontext' do
        it "succeeds #{i} again" do
          expect(@each).to eq('each')
          expect(@all).to eq('all')

          expect(@shared_each).to eq('shared_each')
          expect(@shared_all).to eq('shared_all')
        end
      end
    end
  end

  context 'two context' do
    10.times do |i|
      it "succeeds #{i} time" do
        expect(@each).to eq('each')
        expect(@all).to eq('all')

        expect(@shared_each).to eq('shared_each')
        expect(@shared_all).to eq('shared_all')
      end

      it "succeeds #{i} again" do
        expect(@each).to eq('each')
        expect(@all).to eq('all')

        expect(@shared_each).to eq('shared_each')
        expect(@shared_all).to eq('shared_all')
      end
    end
  end

  after(:each) do
    expect(@each).to eq('each')
    expect(@all).to eq('all')

    expect(@shared_each).to eq('shared_each')
    expect(@shared_all).to eq('shared_all')
  end

  after(:all) do
    expect(@all).to eq('all')

    expect(@shared_all).to eq('shared_all')
  end
end
