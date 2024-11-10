#!/usr/bin/env ruby

require 'psych'

if RUBY_VERSION < '2.4'
  class Hash
    def transform_values
      Hash[map { |k, v| [k, yield(v)] }] # rubocop:disable Style/HashTransformValues
    end
  end

  class Integer
    def positive?
      self > 0 # rubocop:disable Style/NumericPredicate
    end
  end
end

if RUBY_VERSION < '2.7'
  require 'pathname'

  class File
    class << self
      def absolute_path?(file_name)
        Pathname.new(file_name).absolute?
      end
    end
  end
end

if Psych::VERSION < '4.0'
  require 'yaml'

  module YAML
    class << self
      alias unsafe_load load
      alias unsafe_load_file load_file
    end
  end
end
