describe 'Sample', if: true do
  it 'is invoked' do
    expect(true).to be true
  end
end

describe 'Another group' do
  it 'is excellent', if: true do
    expect(true).to be true
  end
end
