# frozen_string_literal: true

$LOAD_PATH.unshift(Pathname(__dir__).join('lib').realpath)

require 'rom/site'

namespace :projects do
  desc 'Symlink project sources'
  task :symlink do
    site = Middleman::Docsite

    projects = site.projects

    projects.select(&:versioned?).each do |project|
      project.versions.each do |version|
        site.clone_repo(project, branch: version[:branch])
        site.symlink_repo(project, version)
      end
    end
  end
end

require 'html-proofer'

def check_links(opts = {})
  HTMLProofer.check_directory('docs',
    { build_dir: 'docs',
      assume_extension: true,
      allow_hash_href: true,
      empty_alt_ignore: true }.merge(opts)
  ).run
rescue => e
  puts e.message
  exit(1)
end

namespace :check_links do
  desc 'Check links'
  task :internal do
    check_links(disable_external: true, file_ignore: [/blog/])
  end
end
