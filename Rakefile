# frozen_string_literal: true

$LOAD_PATH.unshift(Pathname(__dir__).join('lib').realpath)

require 'rom/site'

site = Middleman::Docsite

namespace :projects do
  desc 'Symlink project sources'
  task :symlink do
    projects = site.projects

    projects.select(&:versioned?).each do |project|
      project.versions.each do |version|
        site.clone_repo(project, branch: version[:branch])
        site.symlink_repo(project, version)
      end
    end
  end
end

desc 'Check all links'
task :check_links do
  site.check_links(file_ignore: [/blog/])
end

namespace :check_links do
  desc 'Check internal links'
  task :internal do
    site.check_links(disable_external: true, file_ignore: [/blog/]) or exit(1)
  end

  desc 'Check external links'
  task :external do
    site.check_links(disable_internal: true, file_ignore: [/blog/]) or exit(1)
  end
end
