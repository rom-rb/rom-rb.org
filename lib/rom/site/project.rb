# frozen_string_literal: true

require 'middleman/docsite/project'

module ROM
  module Site
    class Project < Middleman::Docsite::Project
      def org
        'rom-rb'
      end

      def versioned?
        !versions.nil?
      end

      def latest_path
        "/learn/#{slug}/#{latest_version}"
      end

      def file_url(version, source_file)
        branch = versions.detect { |v| v[:value].eql?(version) }[:branch]
        dir = repo.is_a?(Hash) ? "#{repo[:dir]}/" : ""

        repo_path = "#{github_url}/blob/#{branch}/#{dir}docsite/source"
        file_path = source_file.split("/#{version}/")[1..-1].join("/")

        "#{repo_path}/#{file_path}"
      end

      def github_url
        repo.is_a?(Hash) ? repo[:url].gsub('.git', '') : super
      end

      def api_host_url
        "https://api.#{org}.org"
      end
    end
  end
end
