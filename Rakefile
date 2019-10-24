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
