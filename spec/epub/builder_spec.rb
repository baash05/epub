# frozen_string_literal: false

# require_relative '../lib/epub'
require 'json'

RSpec.describe Epub::Builder do
  let(:service) { described_class.new("blarg_blarg.epub") }

  before(:each) do
    allow(Dir).to receive(:chdir).and_yield
    allow(Dir).to receive(:mkdir)
    allow(Dir).to receive(:pwd).and_return("tmp")
    allow(File).to receive(:write)
    allow(Dir).to receive(:entries).and_return([])
    allow(URI).to receive(:open).and_return(double(read: "bloop bloop"))
    allow(Epub::Zipper).to receive(:zip_files)

    allow_any_instance_of(Time).to receive(:to_i).and_return(19730012)
  end

  describe ".add_chapter" do
    subject(:add_chapter) { service.add_chapter("chapter_1", "Chapter One", "Chapter 1 text") }

    it "makes the Text folder" do
      expect(Dir).to receive(:mkdir).with("tmp/blarg_blargepub_19730012/OEBPS/Text")
      add_chapter
    end

    it "writes the content to a file in TEXT" do
      expect(File).to receive(:write).with("OEBPS/Text/chapter_1.xhtml", /Chapter One/)
      add_chapter
    end

    it "adds the id and title to the contents hash" do
     expect{
      add_chapter
     }.to change(service.content, :length).by(1)
      expect(service.content["chapter_1"]).to eq("Chapter One")
    end
  end

  describe ".add_image" do
    it "writes the contest to a file in IMAGES" do
      expect(File).to receive(:write).with("tmp/blarg_blargepub_19730012/OEBPS/Images/puppers.png", anything)
      service.add_image('puppers.png', '/some/image.png')
    end
  end

  describe ".path" do
    it "returns the a timestampped file name" do
      expect(service.path).to include('/blarg_blargepub_19730012/blarg_blarg.epub')
    end
  end

  describe ".style=" do
    before(:each) { service.style = ".h1{color: red;}" }
    it "set the style value" do
       expect(service.style).to eq('.h1{color: red;}')
    end
  end

  describe ".style <<" do
    before(:each) {  service.style = ".h1{color: red;}" }
    before(:each) {  service.style << " .h2{color: blue;}" }
    it "appends the new style on the existing style" do
      expect(service.style).to eq('.h1{color: red;} .h2{color: blue;}')
    end
  end

  describe ".other_data=" do
    it "creates a file with the data" do
      expect(File).to receive(:write).with("tmp/blarg_blargepub_19730012/META-INF/other_data", "{\"hey\":123}")
      service.other_data = {hey: 123}.to_json
    end
  end

  describe ".close" do
    it "creates all the boiler plate files" do
      expect(File).to receive(:write).with("META-INF/container.xml", anything)
      expect(File).to receive(:write).with("META-INF/com.apple.ibooks.display-options.xml", anything)
      expect(File).to receive(:write).with("OEBPS/Styles/style.css", anything)
      expect(File).to receive(:write).with("OEBPS/Text/cover.xhtml", anything)
      expect(File).to receive(:write).with("OEBPS/Text/toc.xhtml", anything)
      expect(File).to receive(:write).with("OEBPS/toc.ncx", anything)
      expect(File).to receive(:write).with("OEBPS/content.opf", anything)
      service.close
    end

    it "calls the zipper" do
      expect(Epub::Zipper).to receive(:zip_files)
      service.close
    end
  end

  describe "#open with block" do
    it "returns the object" do
      obj = Epub::Builder.open("file_name"){ |s| }
      expect(obj).to be_a(Epub::Builder)
    end

    it "calls close" do
      expect_any_instance_of(Epub::Builder).to receive(:close)
      Epub::Builder.open("file_name"){ |s| }
    end
  end
end
