# frozen_string_literal: false

require_relative '../lib/epub/builder'
require 'json'

RSpec.describe Epub do
  it "has a version number" do
    expect(Epub::VERSION).not_to be nil
  end

  describe "example" do
    xit "saves the data" do
      Dir.chdir("tmp") do
        builder = Epub::Builder.open('book2.epub') do |service|
          service.book_title = "Daves Grand Adventure - #{Time.now}"
          service.table_of_contents_title = "Steps into the future"
          service.other_data = { data_id: 123 }.to_json
          service.style = "h2{color: red}"
          service.style << "h2{background-color: blue}"
          service.add_chapter('chap_1', "Chapter 1", "<h2>Hello</h2>From the <i>overworld</i>.")
          service.add_chapter('chap_2', "Chapter 2", "<h2>Waiting</h2>This is the last chapter.")
          service.add_image('puppers.png', '/Users/david/Documents/epub/spec/puppers.png')
          service.cover_file_name = 'puppers.png'
        end
        builder
      end
    end
  end
end
