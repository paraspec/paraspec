describe 'Sample' do
  context 'expensive', paraspec: {group: true} do
    it 'is beautiful' do
      sleep 0.2
      expect(true).to be true
    end

    it 'is beautiful two' do
      sleep 0.2
      expect(true).to be true
    end

    it 'is beautiful three' do
      sleep 0.2
      expect(true).to be true
    end
  end
end
