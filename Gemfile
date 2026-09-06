source('https://rubygems.org')

gemspec

ruby_version = Gem::Version.new(RUBY_VERSION)
gem('psych', '~> 3.3') if ruby_version >= Gem::Version.new('3.1')
gem('racc') if ruby_version >= Gem::Version.new('3.3')

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
