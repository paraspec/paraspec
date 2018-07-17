require 'byebug'
require 'rspec'

# be parallel_rspec -n 4 spec

20.times do |i|
  describe "Foo #{i}" do
    describe 'sub 1' do
      it 'works' do
        sleep 0.5
      end
    end

    describe 'sub 2' do
      it 'works' do
        sleep 0.5
      end
    end
  end
end
