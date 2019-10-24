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
    end
  end
end
