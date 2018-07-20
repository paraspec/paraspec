require 'byebug'
require 'rspec'

# be parallel_rspec -n 4 spec

113.times do |i|
  describe "Foo #{i}" do
    describe 'sub 1' do
      it "works (#{i}-1)" do
        if i == 2
          expect(1).to eq(2)
        else
          sleep 0.15
        end
      end
    end

    describe 'sub 2' do
      it "works (#{i}-2)" do
        if i == 1
        p :actuallyrunningthisthinghere
          pending
          x
        else
          #sleep 0.5
        end
      end
    end
  end
end
#x
