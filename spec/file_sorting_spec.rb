# spec/file_sorting_spec.rb
require 'spec_helper'

RSpec.describe "Directory File Sorting" do
  def sorted_file_content(file_path)
    `sort -f #{file_path}`.split("\n")    # Need to be similar to shell command
  end

  def filtered_files(path, filter)
    Dir.entries(path)
       .reject { |f| File.directory?(File.join(path, f)) || f.start_with?('.') } # Exclude directories and hidden files
       .select { |f| filter.nil? || filter.call(f) }
  end

  directories = {         # Hash
    "dir1" => {           # Nested Hash
      path: "#{LKP_SRC}/distro/adaptation",
      filter: ->(filename) { filename != "README.md" }
    },
    "dir2" => { 
      path: "#{LKP_SRC}/distro/adaptation-pkg", 
      filter: nil 
    },   
    "dir3" => {
      path: "#{LKP_SRC}/programs",
      filter: ->(filename) { filename.start_with?("depends") }
    },
    "dir4" => {
      path: "#{LKP_SRC}/etc",
      filter: ->(filename) { filename != "makepkg.conf" }
    },
  }

  describe "File Sorting Tests" do
    directories.each do |dir_name, config|  # dir_name = dir1, dir2, dir3, dir4 | config = { path: ..., filter: ... }
      context "in #{dir_name}" do           # RSpec test group
        let(:files) { filtered_files(config[:path], config[:filter]) }

        it "has sorted content in each file" do   # single test case
          files.each do |filename|
            file_path = File.join(config[:path], filename)
            next if File.directory?(file_path)

            content = File.readlines(file_path, chomp: true)
            sorted_content = sorted_file_content(file_path)

            expect(content).to eq(sorted_content),
              "Content in #{file_path} is not sorted. " \
              "Expected #{sorted_content}, but got #{content}"
          end
        end
      end
    end
  end
end

