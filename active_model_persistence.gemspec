# frozen_string_literal: true

require_relative 'lib/active_model_persistence/version'

Gem::Specification.new do |spec|
  spec.name = 'active_model_persistence'
  spec.version = ActiveModelPersistence::VERSION
  spec.authors = ['James Couball']
  spec.email = ['couballj@verizonmedia.com']

  spec.summary = 'Adds in-memory persistence to ActiveModel models'
  spec.description = <<~DESCRIPTION
    Adds in-memory persistence to ActiveModel models
  DESCRIPTION
  spec.homepage = 'https://github.com/jcouball/active_model_persistence'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.metadata['source_code_uri']}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'activemodel', '~> 7.0'
  spec.add_dependency 'activesupport', '~> 7.0'

  # Development dependencies
  spec.add_development_dependency 'bump', '~> 0.10'
  spec.add_development_dependency 'bundler-audit', '~> 0.9'
  spec.add_development_dependency 'github_pages_rake_tasks', '~> 0.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'redcarpet', '~> 3.5'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop', '~> 1.24'
  spec.add_development_dependency 'simplecov', '~> 0.21'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yardstick', '~> 0.9'
end
