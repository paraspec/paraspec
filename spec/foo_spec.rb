require 'byebug'
require 'rspec'

# be parallel_rspec -n 4 spec

20.times do |i|
  describe "Foo #{i}" do
  #byebug
    it 'works' do
    #byebug
      sleep 0.5
    end
  end
end
