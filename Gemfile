source "https://rubygems.org"

#if ENV["RBS_VERSION"]
  gem "rbs", github: "Sudachi0814/rbs", branch: "develop"
  # gem "rbs", "~> 3.5" 
#else
#  # Specify your gem's dependencies in typeprof.gemspec
#  gemspec
#end

gem "prism", ">= 1.0.0"

group :development do
  gem "rake"
  gem "stackprof", platforms: :mri
  gem "test-unit"
  gem "simplecov"
  gem "simplecov-html"
  gem "coverage-helpers"
end
