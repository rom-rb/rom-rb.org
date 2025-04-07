source 'https://rubygems.org'

ruby '>= 2.4.1'

gem "rake"

# Middleman gems
gem 'middleman', '5.0.0.rc.1'
gem 'middleman-syntax'
gem 'middleman-blog'
gem "middleman-docsite", git: "https://github.com/dry-rb/middleman-docsite", branch: "main"
gem 'nokogiri'

# Styling
gem 'slim'
gem 'redcarpet'

# Checks html markup
gem 'html-proofer'

group :development do
  gem 'pry-byebug'
  gem 'wdm', '>= 0.1.0' if Gem.win_platform?
  gem 'tzinfo-data' if Gem.win_platform?
end
