# http://stackoverflow.com/a/27013319
require 'rails_helper'

describe I18n do
  it 'interpolate as usual' do
    expect(described_class.interpolate('Show %{model}', model: 'Customer')).to eq 'Show Customer'
  end

  it 'interpolate with number formatting' do
    expect(described_class.interpolate('Show many %<kr>2d', kr: 100)).to eq 'Show many 100'
    expect(described_class.interpolate('Show many %<str>3.3s', str: 'abcde')).to eq 'Show many abc'
  end

  it 'support method execution' do
    expect(described_class.interpolate('Show %{model.downcase}', model: 'Customer')).to eq 'Show customer'
  end
end
