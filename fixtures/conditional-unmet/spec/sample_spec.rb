describe 'Sample', if: false do
  it 'is invoked' do
    expect(true).to be true
  end
end

describe 'Another group' do
  it 'is excellent', if: false do
    expect(true).to be true
  end

  it 'control test' do
  end
end
