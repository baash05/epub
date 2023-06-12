# frozen_string_literal: true

require 'open-uri'
require 'securerandom'
require_relative 'zipper'

module Epub
  class Builder
    def initialize(file_name)
      @file_name = file_name
      @base_path = File.join(Dir.pwd, "#{file_name.delete('.')}_#{Time.now.to_i}")
      @content = {}
      @author_name = ''
      @isbn = '000-0-000000-0'
      @book_title = ''
      @publisher = ''
      @publication_date = Time.now.to_s
      @subject_classification = 'NON000000 NON-CLASSIFIABLE' # The list of options is here https://bisg.org/page/BISACEdition
      @table_of_contents_title = 'Table Of Contents'
      @cover_file_name = nil
      @styles = ''
    end

    def self.open(file_name)
      service = Epub::Builder.new(file_name)

      if block_given?
        yield service
        service.close
      end

      service
    end

    def path
      File.join(@base_path, @file_name)
    end

    attr_accessor :author_name, :isbn, :book_title, :publisher, :publication_date, :subject_classification,
                  :table_of_contents_title, :cover_file_name, :styles, :content

    alias style= styles=
    alias style styles

    def add_chapter(div_id, title, body)
      build_directories
      Dir.chdir(@base_path) do
        persist_raw_content(div_id, title, body)
      end
      @content[div_id] = title
    end

    def add_image(dest_name, sourc_url)
      build_directories
      path = File.join(@base_path, "OEBPS/Images", dest_name)
      File.write(path, URI.open(sourc_url).read) # rubocop:disable Security/Open
    end

    # other_data might be a json payload that could be used by your app
    def other_data=(data)
      build_directories
      path = File.join(@base_path, 'META-INF/other_data')
      File.write(path, data)
    end

    def close
      build_directories
      persist_book_shell # add all the stuff that's not content
      Epub::Zipper.zip_files(@base_path, @file_name)
    end

    private

    # Adds all the files that need to be in place for the book to be considered a book by e-readers
    def persist_book_shell
      Dir.chdir(@base_path) do
        perist_container
        persist_apple_helper_file
        persist_style
        persist_cover
        persist_table_of_content
        persist_table_of_content_ncx
        persist_content_opf
      end
    end

    def build_directories
      @build_directories ||= [@base_path,
                              File.join(@base_path, "META-INF"),
                              File.join(@base_path, "OEBPS"),
                              File.join(@base_path, "OEBPS", "Images"),
                              File.join(@base_path, "OEBPS", "Styles"),
                              File.join(@base_path, "OEBPS", "Text")].
                             each { |path| Dir.mkdir(path) unless Dir.exist?(path) }
    end

    def persist_cover
      if cover_file_name
        persist_raw_content('cover', 'Cover', "<div id=\"cover-image\">
        <img alt=\"#{@book_title}\" src=\"../Images/#{@cover_file_name}\" />
        </div>")
      else
        persist_raw_content('cover', 'Cover',
                            "<h1>#{@book_title}</h1><h3>By: #{@author_name}</h3>")
      end
    end

    def persist_style
      text = []
      text << "body { line-height: 1.5em;} "
      text << 'p.first {text-indent: 0;} '
      text << '@media amzn-mobi {p.first {text-indent: 0;}} '
      text << 'img { max-width: 98%; } #cover-image { text-align: center; }'
      text << '#cover h1{max-width: 75%; "
      text << "         line-height: 1.5em; "
      text << "         text-align: center; "
      text << "         text-transform: uppercase; "
      text << "         padding: 20pt; "
      text << "         color: white; "
      text << "         margin: auto; "
      text << "         margin-top: 20%; "
      text << "         background-color: black; "
      text << "         width: fit-content;}'
      text << '#cover h3{text-align: center;}'
      text << @style
      File.write("OEBPS/Styles/style.css", text.join("\n"))
    end

    def perist_container
      text =  []
      text << '<?xml version="1.0" encoding="UTF-8"?>'
      text << '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
      text << '  <rootfiles>'
      text << '    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>'
      text << '  </rootfiles>'
      text << '</container>'
      File.write('META-INF/container.xml', text.join("\n"))
    end

    def persist_apple_helper_file
      text = <<-FOO
      <?xml version="1.0" encoding="UTF-8"?>
      <display_options>
      <platform name="*">
      <option name="specified-fonts">false</option>
      </platform>
      </display_options>
      FOO
      File.write('META-INF/com.apple.ibooks.display-options.xml', text)
    end

    def persist_raw_content(div_id, title, body)
      text = []
      text << '<?xml version="1.0" encoding="utf-8" standalone="no"?>'
      text << '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
      text << '<html xmlns="http://www.w3.org/1999/xhtml">'
      text << "<head><title>#{title}</title>"
      text << '<link href="../Styles/style.css" rel="stylesheet" type="text/css" />'
      text << '</head><body>'
      text << "<div id=\"#{div_id}\" xml:lang=\"en-US\"> #{body} </div>"
      text << "</body></html>"
      File.write("OEBPS/Text/#{div_id}.xhtml", text.join("\n"))
    end

    def list_dir(dir)
      entries = Dir.entries(dir)
      entries.delete(".")
      entries.delete("..")
      entries.delete(".DS_Store")
      entries
    end

    # <!-- MANIFEST (mandatory)'
    # List of ALL the resources of the book (XHTML, CSS, images,…).'
    # The order of item elements in the manifest is NOT significant.'
    # http://idpf.org/epub/20/spec/OPF_2.0.1_draft.htm#Section2.3 '
    # -->'
    def manifest_text
      text = []
      text << '  <item href="toc.ncx" id="ncx" media-type="application/x-dtbncx+xml" />'
      text << '  <item href="Styles/style.css" id="css" media-type="text/css" />'

      list_dir("OEBPS/Images").each do |entry|
        type = entry.split('.').last
        type = 'jpeg' if type == 'jpg'
        text << "   <item href=\"Images/#{entry}\" id=\"#{entry}\" media-type=\"image/#{type}\" />"
      end
      list_dir("OEBPS/Text").each do |entry|
        text << "   <item href=\"Text/#{entry}\" id=\"#{entry.split('.').first}\" media-type=\"application/xhtml+xml\" />"
      end

      "<manifest>\n#{text.join("\n")}\n</manifest>"
    end

    # <!-- SPINE (mandatory)'
    # The spine element defines the default reading order of the content. '
    # It does not list every file in the manifest, just the reading order.'
    # The value of the idref tag in the spine has to match the ID tag for that entry in the manifest.'
    # For example, if you have the following reference in your manifest:'
    # <item id="chapter-1" href="chapter01.xhtml" media-type="application/xhtml+xml" />'
    # your spine entry would be:'
    # <itemref idref="chapter-1" />'
    # http://idpf.org/epub/20/spec/OPF_2.0.1_draft.htm#Section2.4'
    # -->'
    def spine_text
      text = []
      text << '<spine toc="ncx">'
      text << '  <itemref idref="cover" />'
      text << '  <itemref idref="toc" />'
      @content.each do |div_id, _|
        text << "  <itemref idref=\"#{div_id}\" />"
      end
      text << '</spine>'
      text.join("\n")
    end

    # <!-- GUIDE (optional, recommended by Apple)
    # The guide lets you specify the role of the book's files.
    # Available tags: cover, title-page, toc, index, glossary, acknowledgements, bibliography,
    # colophon, copyright-page, dedication, epigraph, foreword, loi (list of illustrations),
    # lot (list of tables), notes, preface, and text.
    # http://idpf.org/epub/20/spec/OPF_2.0.1_draft.htm#Section2.6
    #  -->
    def guide_text
      text = []
      text << '<guide>'
      list_dir("OEBPS/Text").each do |entry|
        name = entry.split('.').first
        type = Epub::APPLE_GUIDE_TYPES.include?(name) ? name : "text"
        text << "  <reference href=\"Text/#{entry}\" title=\"#{name}\" type=\"#{type}\" />"
      end
      text << '</guide>'
      text.join("\n")
    end

    def meta_text
      text = []
      text << '<metadata xmlns:opf="http://www.idpf.org/2007/opf" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
      text << "  <dc:identifier id=\"bookid\" opf:scheme=\"ISBN\">urn:isbn:#{@isbn}</dc:identifier>"
      text << "  <dc:title>#{@book_title}</dc:title>"
      text << "  <dc:rights>Copyright © #{Time.now.year} #{@author_name}. All rights reserved.</dc:rights>"
      text << "  <dc:subject>#{@subject_classification}</dc:subject>"
      text << "  <dc:creator opf:file-as=\"#{@author_name}\" opf:role=\"aut\">#{@author_name}</dc:creator>"
      text << '  <dc:source>https://calypso.net</dc:source>'
      text << "  <dc:publisher>#{@publisher}</dc:publisher>"
      text << "  <dc:date opf:event=\"publication\">#{Time.now}</dc:date>"
      text << '  <dc:language>en</dc:language>' # http://en.wikipedia.org/wiki/List_of_ISO_639-2_codes
      text << "  <dc:identifier opf:scheme=\"UUID\">urn:uuid:#{SecureRandom.uuid}</dc:identifier>"
      text << "  <meta name=\"cover\" content=\"#{@cover_file_name}\" />"
      text << '</metadata>'
      text.join("\n")
    end

    def persist_content_opf
      text = []
      text << '<?xml version="1.0" encoding="utf-8" standalone="yes"?>'
      text << '<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="bookid" version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/">'
      text << meta_text
      text << manifest_text
      text << spine_text
      text << guide_text
      text << '</package>'

      File.write('OEBPS/content.opf', text.join("\n"))
    end

    def persist_table_of_content_ncx
      text = []
      text << '<?xml version="1.0" encoding="UTF-8" standalone="no" ?>'
      text << '<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">'
      text << '<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">'
      text << '<head>'
      text << "<meta content=\"urn:isbn:#{@isbn}\" name=\"dtb:uid\"/>"
      text << '<meta content="1" name="dtb:depth"/>'
      text << '<meta content="0" name="dtb:totalPageCount"/>'
      text << '<meta content="0" name="dtb:maxPageNumber"/>'
      text << '</head>'
      text << "<docTitle><text>#{@book_title}</text></docTitle>"
      text << '<navMap>'
      text << '<navPoint id="navpoint-cover"><navLabel><text>Cover</text></navLabel><content src="Text/cover.xhtml" /></navPoint>'
      @content.each do |div_id, title|
        text << "<navPoint id=\"#{div_id}\"><navLabel><text>#{title}</text></navLabel><content src=\"Text/#{div_id}.xhtml\" /></navPoint>"
      end
      text << '</navMap>'
      text << '</ncx>'

      File.write('OEBPS/toc.ncx', text.join("\n"))
    end

    def persist_table_of_content
      text = []
      text << '<?xml version="1.0" encoding="utf-8" standalone="no"?>'
      text << '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"'
      text << '"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
      text << '<html xmlns="http://www.w3.org/1999/xhtml">'
      text << '<head>'
      text << " <title>#{@table_of_contents_title}</title>"
      text << ' <link href="../Styles/style.css" rel="stylesheet" type="text/css" />'
      text << '</head>'
      text << '<body>'
      text << ' <div id="toc" xml:lang="en-US">'
      text << " <h1>#{@table_of_contents_title}</h1>"
      text << ' <ul>'

      @content.each do |div_id, title|
        text << "  <li><a href=\"../Text/#{div_id}.xhtml\"><span>#{title}</span></a></li>"
      end

      text << ' </ul>'
      text << '</div></body></html>'

      File.write('OEBPS/Text/toc.xhtml', text.join("\n"))
    end
  end
end
