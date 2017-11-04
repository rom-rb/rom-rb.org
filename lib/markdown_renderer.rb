require 'middleman-core/renderers/redcarpet'

class MarkdownRenderer < Middleman::Renderers::MiddlemanRedcarpetHTML
  DEFAULT_OPTS = {
    tables: true,
    autolink: true,
    gh_blockcode: true,
    fenced_code_blocks: true,
    with_toc_data: true
  }

  def initialize(options = {})
    super(options.merge(DEFAULT_OPTS))
  end

  def link(link, title, content)
    if content.start_with?('api::')
      _, project, klass = content.split('::')
      link_to_api(project, klass, link)
    elsif link['%{version}']
      super(link % { version: scope.version }, title, content)
    else
      super
    end
  end

  def link_to_api(project, klass, meth)
    path = klass ? klass.gsub('::', '/') : ''

    anchor = if meth.include?('#')
               "#{meth}-instance_method".gsub('#', '')
             elsif meth.include?('.')
               "#{meth}-class_method".gsub('#', '')
             end

    if anchor
      content = path.empty? ? meth : "#{path.gsub('/', '::')}#{meth}"

      link(
        config.api_anchor_url_template % { project: project, path: path, anchor: anchor },
        nil, content
      )
    else
      content = path.empty? ? "ROM::#{meth}" : "ROM::#{path.gsub('/', '::')}::#{meth}"

      link(
        config.api_url_template % { project: project, path: "#{path}/#{meth}" },
        nil, content
      )
    end
  end

  def config
    scope.config
  end
end
