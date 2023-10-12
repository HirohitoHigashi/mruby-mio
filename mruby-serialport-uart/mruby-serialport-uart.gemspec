# frozen_string_literal: true

require_relative "lib/mruby/uart/serialport/version"

Gem::Specification.new do |spec|
  spec.name = "mruby-serialport-uart"
  spec.version = UART::VERSION
  spec.authors = ["HirohitoHigashi"]
  spec.email = ["higashi@s-itoc.jp"]

  spec.summary = "UART class library using serialport gem. compliant with mruby, mruby/c common I/O API guidelines."
# spec.description = ""
  spec.homepage = "https://github.com/HirohitoHigashi/mruby-mio/tree/main/mruby-serialport-uart"
  spec.required_ruby_version = ">= 2.6.0"
  spec.license = "BSD 3-CLAUSE"

# spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
# spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
# spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["README.md", "LICENSE", "lib/**/*"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "serialport"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
