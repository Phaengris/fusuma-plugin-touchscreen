# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fusuma/plugin/touchscreen/version'

Gem::Specification.new do |spec|
  spec.name          = 'fusuma-plugin-touchscreen'
  spec.version       = Fusuma::Plugin::Touchscreen::VERSION
  spec.authors       = ['Mikhail Fedotov']
  spec.email         = ['myf.ivm@gmail.com']

  spec.summary       = ' Touchscreen support plugin for Fusuma '
  spec.description   = ' fusuma-plugin-touchscreen is Fusuma plugin for support touchscreen devices. '
  spec.homepage      = 'https://github.com/Phaengris/fusuma-plugin-touchscreen'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  spec.files          = Dir['{bin,lib,exe}/**/*', 'LICENSE*', 'README*', '*.gemspec']
  spec.test_files     = Dir['{test,spec,features}/**/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3' # https://packages.ubuntu.com/search?keywords=ruby&searchon=names&exact=1&suite=all&section=main

  spec.add_dependency 'fusuma', '~> 2.0'
end
