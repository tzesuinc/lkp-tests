# spec/file_sorting_spec.rb
require 'spec_helper'

RSpec.describe "Directory File Sorting" do
  # Define directories and their specific conditions
  directories = {
    "dir1" => {
      path: "#{LKP_SRC}/distro/adaptation", # Replace with actual path
      filter: ->(filename) { filename != "README.md" } # Exclude README.md
    },
    "dir2" => { 
      path: "#{LKP_SRC}/distro/adaptation-pkg", 
      filter: nil 
    },   
    "dir3" => {
      path: "#{LKP_SRC}/programs", # Replace with actual path
      filter: ->(filename) { filename.start_with?("depends") } # Only files starting with "depends"
    },
    "dir4" => {
      path: "#{LKP_SRC}/etc", # Replace with actual path
      filter: ->(filename) { filename != "makepkg.conf" } # Exclude makepkg.conf
    },
  }

  directories.each do |dir_name, config|
    context "in #{dir_name}" do
      let(:files) do
        Dir.entries(config[:path])
           .reject { |f| File.directory?(File.join(config[:path], f)) } # Exclude directories
           .reject { |f| f.start_with?('.') } # Exclude hidden files
           .select { |f| config[:filter].nil? || config[:filter].call(f) } # Apply custom filter if present
      end

      it "has sorted content in each file" do
        files.each do |filename|
          file_path = File.join(config[:path], filename)
          next if File.directory?(file_path)

          content = File.readlines(file_path, chomp: true)
          sorted_content = `sort -f #{file_path}`.split("\n")

          expect(content).to eq(sorted_content),
            "Content in #{file_path} is not sorted. " \
            "Expected #{sorted_content}, but got #{content}"
        end
      end
    end
  end
end

