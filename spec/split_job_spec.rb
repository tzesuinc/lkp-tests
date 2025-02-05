require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require "#{LKP_SRC}/lib/bash"
require "#{LKP_SRC}/lib/yaml"

describe 'lkp-split-job' do
  before(:all) do
    @tmp_src_dir = Dir.mktmpdir(nil, '/tmp')

    `rsync -aix #{LKP_SRC}/ #{@tmp_src_dir}`
    `rsync -aix #{LKP_SRC}/spec/split-job/tests #{LKP_SRC}/spec/split-job/include #{@tmp_src_dir}/`

    Dir.chdir(@tmp_src_dir) do
      `bash -c "export LKP_SRC=#{@tmp_src_dir}; . #{@tmp_src_dir}/lib/host.sh; create_host_config"`
    end
  end

  after(:all) do
    FileUtils.rm_rf @tmp_src_dir
  end

  before(:each) do
    @tmp_dir = Dir.mktmpdir(nil, '/tmp')
  end

  after(:each) do
    FileUtils.rm_rf @tmp_dir
  end

  def execute_test(id)
    `LKP_SRC=#{@tmp_src_dir} #{@tmp_src_dir}/bin/lkp split-job -t lkp-tbox -o #{@tmp_dir} spec/split-job/#{id}.yaml`

    Dir[File.join(@tmp_dir, "#{id}-*.yaml")].each do |actual_yaml|
      `sed -i 's/:#! /#!/g' #{actual_yaml}`

      actual = YAML.load_file(actual_yaml)
      expect = YAML.load_file("#{LKP_SRC}/spec/split-job/#{File.basename(actual_yaml)}")

      expect(actual).to eq expect
    end
  end

  it 'split with --compatible option' do
    Dir.chdir(@tmp_src_dir) do
      `LKP_SRC=#{@tmp_src_dir} #{@tmp_src_dir}/bin/lkp split-job --compatible -o #{@tmp_dir} spec/split-job/compatible.yaml`
      new_yaml = 'compatible-test_1.yaml'
      # delete machine specific settings
      %w[testbox tbox_group local_run memory nr_cpu ssd_partitions hdd_partitions].each { |s| `sed -i '/#{s}:/d' #{File.join(@tmp_dir, new_yaml)}` }
      actual = YAML.load_file(File.join(@tmp_dir, new_yaml))
      expect = YAML.load_file("#{LKP_SRC}/spec/split-job/#{new_yaml}")

      expect(actual).to eq expect
    end
  end

  it "split job['split-job']['test'] only" do
    execute_test(1)
  end

  it "split job['split-job']['test'] and job['split-job']['group']" do
    execute_test(2)
  end

  it "split job['fs'] only" do
    execute_test(3)
  end
end
