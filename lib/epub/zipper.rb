# frozen_string_literal: true

require "zip"
require "open-uri"

# Under the hood an epub is really just a zip with a known set of flies,
# and a bit not compressed
# this class is responsible for adding the non-zip bits, and then
# taking all the content in the folder, and constructing the epub file.
module Epub
  class Zipper
    class << self
      def zip_files(source_directory, file_name)
        Dir.chdir(source_directory) do
          initialize_stream(file_name)
          Zip::File.open(file_name, true) do |zip_file|
            files = Dir[File.join(source_directory, "**/*")]
            directories, file_names = files.partition { |f| File.directory?(f) }
            create_directories(zip_file, directories)
            copy_files(zip_file, file_names)
          end
        end
      end

      # The zip stream MIMETYPE has to be done without compression.
      # This is required by the ebook standards
      def initialize_stream(file_name)
        ::Zip::OutputStream.open(file_name) do |stream|
          stream.put_next_entry('mimetype', nil, nil, ::Zip::Entry::STORED)
          stream.write 'application/epub+zip'
        end
      end

      def create_directories(zip_file, directories)
        directories.each do |name|
          zip_file_path = name.gsub(Dir.pwd, "")[1..]
          zip_file.mkdir(zip_file_path)
        end
      end

      def copy_files(zip_file, file_names)
        file_names.each do |name|
          content = File.open(name, "rb").read
          zip_file_path = name.gsub(Dir.pwd, "")[1..]
          zip_file.get_output_stream(zip_file_path) { |f| f.puts(content) }
        end
      end
    end
  end
end
