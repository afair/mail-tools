# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mail/tools/version'

Gem::Specification.new do |spec|
  spec.name          = "mail-tools"
  spec.version       = Mail::Tools::VERSION
  spec.authors       = ["Allen Fair"]
  spec.email         = ["allen.fair@gmail.com"]
  spec.summary       = %q{Mail::Tools extensions for handling email messages}
  spec.description   = %q{Mail::Tools extensions for handling email messages}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "mail", "~> 2.6.3"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.5.0"
  spec.add_development_dependency "minitest-ansi"
end
