require 'spec_helper'
require "#{LKP_SRC}/lib/kernel_tag"

describe '#kernel_match_version?' do
  [
    ['v5.10', ['== v5.9'], false],
    ['v5.9', ['== v5.9'], true],
    ['v5.10', ['<= v5.10'], false],
    ['v5.11', ['<= v5.10'], false],
    ['v5.9', ['<= v5.10'], true],
    ['v5.10', ['>= v5.9'], true],
    ['v5.10', ['>= v5.10'], true],
    ['v5.8', ['>= v5.10'], false],
    ['v5.11', ['> v5.10'], true],
    ['v5.9', ['> v5.10'], false],
    ['v5.11', ['< v5.10'], true],
    ['v5.9', ['< v5.10'], false],
    ['v5.7-rc1', ['>= v5.7-rc2'], false],
    ['v5.7-rc1', ['<= v5.7-rc2'], true],
    ['v5.7-rc2', ['>= v5.8-rc2'], false],
    ['v5.7-rc2', ['<= v5.7-rc1'], false],
    ['v5.7-rc2', ['>= v5.7-rc2'], true],
    ['v5.7-rc2', ['< v5.7-rc1'], true],
    ['v5.8-rc2', ['>= v5.7-rc2'], true],
    ['v5.7-rc3', ['== v5.7'], false]
  ].each do |test|
    it "handles #{test}" do
      expect(kernel_match_version?(test[0], test[1])).to eq(test[2])
    end
  end
end
