20.times do |i|
  describe 'Group #{i}' do
    it "succeeds #{i} time" do
      sleep 0.5
    end
  end
end
