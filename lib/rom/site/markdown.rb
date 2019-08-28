# frozen_string_literal: true

require 'middleman/docsite/markdown/renderer'

module ROM
  module Site
    module Markdown
      class Renderer < Middleman::Docsite::Markdown::Renderer
        def link(link, title, content)
          if content.start_with?('api::')
            _, project, path = content.split('::')
            link_to_api(project, path, link)
          elsif link['%<version>s']
            super(link % { version: scope.version }, title, content)
          else
            super
          end
        end

        def link_to_api(project, path, target)
          klass = path.gsub('/', '::') if path

          if target.start_with?('#') || target.start_with?('.')
            content = "#{klass}#{target}"
            tokens = { project: project, path: path, anchor: anchor(target) }

            link(
              config.api_anchor_url_template % tokens,
              nil, content
            )
          else
            content = ['ROM', *klass, target].join('::')
            path    = [*path, target].join('/')

            link(
              config.api_url_template % { project: project, path: path },
              nil, content
            )
          end
        end
      end
    end
  end
end
