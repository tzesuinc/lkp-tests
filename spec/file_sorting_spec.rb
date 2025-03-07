require 'spec_helper'

def sorted_file_content(file_path)
  `LC_ALL=C sort -f #{file_path} | uniq`
end

def filtered_files(path, filter)
  Dir.entries(path)
     .reject { |f| File.symlink?(File.join(path, f)) || File.directory?(File.join(path, f)) || f.start_with?('.') }
     .select { |f| filter.nil? || filter.call(f) }
end

describe 'Directory File Sorting' do
  directories = {
    'adaptation' => {
      path: "#{LKP_SRC}/distro/adaptation",
      filter: ->(filename) { filename != 'README.md' }
    },
    'adaptation_pkg' => {
      path: "#{LKP_SRC}/distro/adaptation-pkg"
    },
    'programs' => {
      path: "#{LKP_SRC}/programs",
      filter: ->(filename) { filename.start_with?('depends') }
    },
    'etc' => {
      path: "#{LKP_SRC}/etc",
      filter: ->(filename) { filename != 'makepkg.conf' && filename !~ /\.(rb|yml)$/ }
    }
  }

  directories.each do |dir_name, config|
    context "in #{dir_name}" do
      filtered_files(config[:path], config[:filter]).each do |filename|
        file_path = File.join(config[:path], filename)

        it "#{file_path} has sorted content and no duplicates" do
          expect(File.read(file_path)).to eq(sorted_file_content(file_path))
        end
      end
    end
  end
end
