# frozen_string_literal: true

require_relative "lib/rdawn/version"

Gem::Specification.new do |spec|
  spec.name = "rdawn"
  spec.version = Rdawn::VERSION
  spec.authors = ["Enrique Meza C"]
  spec.email = ["emezac@gmail.com"]

  spec.summary = "A Ruby framework for building robust, web-native AI agents."
  spec.description = "rdawn is an open-source framework for Ruby, built on Ruby on Rails 8.0, designed for creating robust, web-native AI agents."
  spec.homepage = "https://github.com/emezac/rdawn"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/emezac/rdawn"
  spec.metadata["changelog_uri"] = "https://github.com/emezac/rdawn/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x00", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile]) ||
        f.end_with?('.gem')
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "activesupport"
  spec.add_dependency "httpx"
  spec.add_dependency "open_router"
  spec.add_dependency "openai"
  spec.add_dependency "raix"
  spec.add_dependency "zeitwerk"
  spec.add_dependency "mime-types", "~> 3.0"  # For file upload content type detection
  spec.add_dependency "concurrent-ruby", "~> 1.2"  # For async MCP execution
  spec.add_dependency "rufus-scheduler", "~> 3.9"  # For cron job scheduling

  # Development dependencies
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.23"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "yard"
end
