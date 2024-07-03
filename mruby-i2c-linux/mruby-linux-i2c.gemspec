# frozen_string_literal: true

require_relative "lib/mruby/i2c/linux/version"

Gem::Specification.new do |spec|
  spec.name          = "mruby-i2c-linux"
  spec.version       = I2C::VERSION
  spec.authors       = ["HirohitoHigashi"]
  spec.email         = ["higashi@s-itoc.jp"]

  spec.summary = "I2C bus driver class library using Linux i2cdev. Compliant with mruby, mruby/c common I/O API guidelines."
#  spec.description = ""
  spec.homepage = "https://github.com/HirohitoHigashi/mruby-mio/"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")
  spec.license = "BSD 3-CLAUSE"

#  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/HirohitoHigashi/mruby-mio/tree/v#{spec.version}/#{spec.name}"
  spec.metadata["documentation_uri"] = "https://www.rubydoc.info/gems/#{spec.name}/#{spec.version}/"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["README.md", "LICENSE", "lib/**/*"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end