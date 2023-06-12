# Epub Builder
Convert html text, and images into Epub files, that can be viewed on most modern operating systems, and uploaded to amazon kindle devices.

## In Rails
Add this to your gem file
```
gem 'epub'
```

## Usage
**All actions on the epub should be done inside an open block, much like the use of File**

### Attributes (and defaults)
  - author_name = ''
  - isbn = '000-0-000000-0'
  - book_title = ''
  - publisher = ''
  - publication_date = Time.now.to_s
  - table_of_contents_title = 'Table Of Contents'
  - cover_file_name = ''
  - styles = ''
  - subject_classification = 'NON000000 NON-CLASSIFIABLE'
    * **NOTE**: The list of options for _subject_classification_ can be found here https://bisg.org/page/BISACEdition
    * Amazon makes use of this info
  - other_data = ''
    - Other data is something I've added, should there come a time you'd want to reverse the process.  I've personally used the data to import an exported epub.
    - This data gets persisted in a file name 'other_data' in the META-INF folder.

### Methods
   - **Start the block**
    <br>`Epub::Builder.open(file_name) { |service| ... }`

  - **Find the path of the produced file**
    <br>`service.path`

  - **Add A Chapter**
    <br>`service.add_chapter(id, title, text)`

  - **Add An Image**
    <i>
      <br>All images that you use in your html based chapters, or as the cover page, get added through this method.
      <br>The order added is not important
    </i>
    <br>`service.add_image(intenal_file_name, source_file_name)`

## Non Chapter Magic
  - **Why?**
  Apple treat some "node" ids in a special way.  It's an ever changing way. It's courage that they don't tell devs.
  - **The List Of Options**
    - index
    - glossary
    - acknowledgements
    - bibliography
    - colophon
    - copyright-page
    - dedication
    - epigraph
    - foreword
    - notes
    - preface
    - loi # List of images
    - lot # List of tables

## EXAMPLES

- ### Create a simple 1 chapter epub, with no cover
  ```
    Dir.chdir(Dir.tmpdir) do
      Epub::Builder.open('1_chapter.epub') do |service|
        service.author_name = "David Rawk"
        service.book_title = "Dave's Grand Tour"
        service.add_chapter('chap_1', "Chapter 1", "<h2>Hello</h2>From <b>the</b> <i>over<s>world</s></i>.")
      end
    end
  ```

- ### Create a simple 2 chapter Epub with a cover image, some 'other_data' and an extended style
  ```
    Dir.chdir(Dir.tmpdir) do
      Epub::Builder.open('1_chapter.epub') do |service|
        service.author_name = "David Rawk"
        service.book_title = "I Love Puppies"
        service.add_chapter('chap_1', "Chapter 1", "Puppies are the best!")
        service.add_chapter('chap_2', "Chapter 2", "They all need love")

        # Add a cover image
        service.add_image('puppers.png', 'epub/lib/epub/puppers.png')
        service.cover_file_name = 'puppers.png'

        # Add "other_data" to the epub
        service.other_data = {user_id: 123, user_status: :awesome }.to_json

        # Extend the style a bit.
        service.style = "h2{color: red;}"
        service.style << "h2{background-color: blue;}"
      end
    end
  ```
