describe 'Sample' do
  it 'is beautiful' do
    expect(true).to be true
  end

  it 'is upcoming' do
    skip 'not yet'
  end

  it 'is also upcoming' do
    skip 'not yet either'
  end
end

describe 'Another group' do
  it 'is not good' do
    expect(true).to be false
  end
end
