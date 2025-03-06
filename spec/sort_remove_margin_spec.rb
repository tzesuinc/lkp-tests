require 'spec_helper'
require "#{LKP_SRC}/lib/stats"

describe 'sort_remove_margin' do
  # MARGIN_SHIFT = 5
  arr = [*1..70]

  context 'when an input array is empty' do
    it 'returns an empty array' do
      expect(sort_remove_margin([])).to eq([])
    end
  end

  context 'when an input array is not empty and no max_margin is provided' do
    it 'sorts the array and remove the margin from both ends' do
      expect(sort_remove_margin(arr)).to eq([*3..68])
    end
  end

  context 'when an input array is not empty and a max_margin is provided' do
    it 'sorts the array and remove the margin (based on the min of calculated margin and max margin) from both ends' do
      expect(sort_remove_margin(arr, 1)).to eq([*2..69])
    end
  end

  context 'when an input array is not empty and margin value is too large' do
    it 'returns an empty array' do
      stub_const('MARGIN_SHIFT', 1)
      expect(sort_remove_margin(arr)).to eq([])
    end
  end
end
