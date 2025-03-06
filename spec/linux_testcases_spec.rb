require 'spec_helper'
require "#{LKP_SRC}/lib/stats"

describe '#functional_test?' do
  %w[lkvs locktorture].each do |test|
    it "returns the index for #{test} in LINUX_TESTCASES" do
      expect(functional_test?(test)).to be_truthy
    end
  end

  it 'returns nil for a test case not in LINUX_TESTCASES' do
    expect(functional_test?('non-existent-test')).to be_falsey
  end
end

describe '#other_test?' do
  %w[borrow btest].each do |test|
    it "returns the index for #{test} in LINUX_TESTCASES" do
      expect(other_test?(test)).to be_truthy
    end
  end

  it 'returns nil for a test case not in OTHER_TESTCASES' do
    expect(other_test?('non-existent-test')).to be_falsey
  end
end
