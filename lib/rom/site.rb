# frozen_string_literal: true

require 'html-proofer'
require 'middleman/docsite'

require 'rom/site/project'
require 'rom/site/markdown'

Middleman::Docsite.configure do |config|
  config.project_class = ROM::Site::Project
  config.projects_subdir = 'learn'
end

module Middleman::Docsite
  def self.check_links(opts = {})
    HTMLProofer.check_directory('docs',
      { build_dir: 'docs',
        assume_extension: true,
        allow_hash_href: true,
        empty_alt_ignore: true }.merge(opts)
    ).run
  rescue => e
    puts e.message
    false
  end
end