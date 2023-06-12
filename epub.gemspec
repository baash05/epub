# frozen_string_literal: true

require_relative "lib/epub/version"

Gem::Specification.new do |spec|
  spec.name = "epub"
  spec.version = Epub::VERSION
  spec.authors = ["baash05"]
  spec.email = ["david.rawk@gmail.com"]

  spec.summary = "Allows user to generate ebpub from html based"
  spec.description = "Allow users of this gem to create ebpubs with simple html and images"
  spec.homepage = "https://r.mtdv.me/e47329ded1"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://r.mtdv.me/e47329ded1"
  spec.metadata["changelog_uri"] = "https://r.mtdv.me/e47329ded1"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "open-uri"
  spec.add_dependency "rubyzip"
  spec.add_dependency "securerandom"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
