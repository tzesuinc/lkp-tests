require 'spec_helper'
require "#{LKP_SRC}/lib/bash"

describe 'xfstests' do
  describe 'is_test_in_group' do
    before(:all) do
      @benchmark_root = File.join(LKP_SRC, 'spec', 'benchmark_root')
    end

    it 'judges the belonging case' do
      [
        { test: 'xfs-no-xfs-bug-on-assert', group: 'xfs-no-xfs-bug-on-assert' },
        { test: 'xfs-115', group: 'xfs-no-xfs-bug-on-assert' },
        { test: 'xfs-276', group: 'xfs-realtime' },
        { test: 'xfs-114', group: 'xfs-reflink-rmapbt' },
        { test: 'xfs-307', group: 'xfs-scratch-reflink-[0-9]*' },
        { test: 'xfs-235', group: 'xfs-scratch-rmapbt' },
        { test: 'generic-510', group: 'generic-group-[0-9]*' },
        { test: 'generic-437', group: 'generic-dax' },
        { test: 'generic-457', group: 'generic-logwrites' },
        { test: 'generic-487', group: 'generic-logdev' },
        { test: 'ext4-029', group: 'ext4-logdev' },
        { test: 'xfs-275', group: 'xfs-logdev' }
      ].each do |entry|
        expect(Bash.call("source #{LKP_SRC}/lib/tests/xfstests.sh; export BENCHMARK_ROOT=#{@benchmark_root}; is_test_in_group \"#{entry[:test]}\" \"#{entry[:group]}\"; echo $?")).to eq('0')
      end
    end

    it 'judges the non belonging case' do
      [
        { test: 'generic-437', group: 'generic-group-[0-9]*' },
        { test: 'ext4-group-00', group: 'ext4-logdev' },
        { test: 'xfs-115', group: 'generic-dax' },
        { test: 'generic-510', group: 'generic-dax' },
        { test: 'xfs-114', group: 'xfs-scratch-reflink-[0-9]*' }
      ].each do |entry|
        expect(Bash.call("source #{LKP_SRC}/lib/tests/xfstests.sh; export BENCHMARK_ROOT=#{@benchmark_root}; is_test_in_group \"#{entry[:test]}\" \"#{entry[:group]}\"; echo $?")).to eq('1')
      end
    end
  end
end
