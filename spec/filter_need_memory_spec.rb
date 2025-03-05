require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require "#{LKP_SRC}/lib/job"
require "#{LKP_SRC}/lib/bash"

system_free_mem_gb = Integer(Bash.call("free -g | sed -n '2, 1p' | awk '{print $7}'"))

describe 'filters/need_memory' do
  before(:all) do
    @tmp_dir = LKP::TmpDir.new('filter-need-memory-spec-')
    @tmp_dir.add_permission
    @test_yaml_file = @tmp_dir.path('test.yaml')
  end

  after(:all) do
    @tmp_dir.cleanup!
  end

  def generate_job(contents)
    File.open(@test_yaml_file, 'w') do |f|
      f.write(contents.to_yaml)
    end
    Job.open(@test_yaml_file)
  end

  context 'when do not have need_memory' do
    it 'does not filter the job' do
      job = generate_job('testcase' => 'testcase')
      job.expand_params
    end
  end

  context 'when need_memory smaller than available_memory' do
    it 'does not filter the job' do
      job = generate_job('testcase' => 'testcase', 'need_memory' => "#{system_free_mem_gb - 1}G")
      job.expand_params
    end
  end

  context 'when need_memory larger than available_memory' do
    it 'filter the job' do
      job = generate_job('testcase' => 'testcase', 'need_memory' => '100%', 'nr_cpu' => system_free_mem_gb + 2)
      expect { redirect_to_string { job.expand_params } }.to raise_error Job::ParamError
    end
  end
end
