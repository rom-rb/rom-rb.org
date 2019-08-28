# frozen_string_literal: true

require 'middleman/docsite'

require 'rom/site/project'
require 'rom/site/markdown'

Middleman::Docsite.configure do |config|
  config.project_class = ROM::Site::Project
end
