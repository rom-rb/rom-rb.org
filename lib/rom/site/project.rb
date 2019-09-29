# frozen_string_literal: true

require 'middleman/docsite/project'

module ROM
  module Site
    class Project < Middleman::Docsite::Project
      def org
        'rom-rb'
      end
    end
  end
end
