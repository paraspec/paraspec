require 'rspec'

20.times do |i|
  describe "Foo #{i}" do
    it 'works' do
      sleep 0.5
    end
  end
end
