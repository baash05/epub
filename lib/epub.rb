# frozen_string_literal: true

require_relative "epub/version"
require_relative "epub/builder"

module Epub
  # When you add a CONTENT ELEMENT, naming the div_id according to the APPLE_GUIDE_TYPES
  # allows apple to treat the files differently
  # I have no idea how it does it, or what it does, but Apple likes it.
  # It is not required, and naming your CONTENT ELEMENT something else
  # will tell apple it's "text"
  APPLE_GUIDE_TYPES = %w[
    index
    glossary
    acknowledgements
    bibliography
    colophon
    copyright-page
    dedication
    epigraph
    foreword
    notes
    preface
    loi
    lot
  ].freeze # lot => "list of tables", #loi => "list of images"

  def self.example_use
    Epub::Builder.open('daves_book.epub') do |file|
      file.author_name = "David Rawk"
      file.isbn = "8675-309"
      file.book_title = "Dave's Grand #{Time.now}"
      file.publisher = "Dave's Publishing House"
      file.subject_classification = 'NON000000 NON-CLASSIFIABLE' # The list of options is here https://bisg.org/page/BISACEdition
      file.table_of_contents_title = "Dave's Table Of Content"
      file.meta_data = { data_id: 123 }.to_json
      file.style = "h2{color: red}"
      file.style << "h2{background-color: blue}"
      file.add_content('chap_1', "Chapter 1", "<h2>Hello</h2>From the <i>overworld</i>.")
      file.add_content('chap_2', "Chapter 2", "<h2>Hello</h2>From the <i>overworld</i>.")
      file.add_image('puppers.png', 'epub/lib/epub/puppers.png')
      file.cover_file_name = 'puppers.png'
    end
  end
end
