require 'rspec'

$LOAD_PATH.delete_if { |p| File.expand_path(p) == File.expand_path('./lib') }

if ENV['GENERATE_COVERAGE'] == 'true'
  require 'simplecov'
  require 'simplecov-rcov'
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end

LKP_SRC ||= ENV['LKP_SRC'] || File.expand_path(File.join(File.dirname(__FILE__), '..'))

require "#{LKP_SRC}/lib/lkp_tmpdir"
