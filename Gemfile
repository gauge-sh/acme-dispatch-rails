source "https://rubygems.org"

# We depend on the Rails frameworks we actually use rather than the rails
# meta-gem: this app has no mailers, jobs, cable, or storage.
gem "actionpack", "~> 8.1.3"
gem "actionview", "~> 8.1.3"
gem "activemodel", "~> 8.1.3"
gem "activerecord", "~> 8.1.3"
gem "activesupport", "~> 8.1.3"
gem "railties", "~> 8.1.3"

gem "devise", "~> 4.9"
gem "propshaft"
gem "puma", ">= 6.0"
gem "sqlite3", ">= 2.1"

group :development, :test do
  gem "debug", platforms: %i[ mri ], require: "debug/prelude"
end

group :development do
  gem "packwerk", "~> 3.2"
  gem "rubocop-rails-omakase", require: false
end
