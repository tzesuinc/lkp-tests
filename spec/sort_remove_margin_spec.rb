require 'spec_helper'
require "#{LKP_SRC}/lib/stats"

MARGIN_SHIFT = 2
describe 'sort_remove_margin' do
  arr = [4, 1, 7, 3, 2, 10, 6, 8, 9, 5]

  context 'when an input array is empty' do
    it 'returns an empty array' do
      expect(sort_remove_margin([])).to eq([])
    end
  end

  context 'when an input array is not empty and no max_margin is provided' do
    it 'sorts the array and remove the margin from both ends' do
      expect(sort_remove_margin(arr)).to eq([3, 4, 5, 6, 7, 8])
    end
  end

  context 'when an input array is not empty and a max_margin is provided' do
    it 'sorts the array and remove the margin (based on the min of calculated margin and max margin) from both ends' do
      expect(sort_remove_margin(arr, 1)).to eq([2, 3, 4, 5, 6, 7, 8, 9])
    end
  end

  context 'when an input array is not empty and margin value is too large' do
    it 'returns an empty array' do
      stub_const('MARGIN_SHIFT', 1)
      arr = [7, 3, 2, 10]
      expect(sort_remove_margin(arr)).to eq([])
    end
  end
end
