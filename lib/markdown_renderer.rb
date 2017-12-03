require 'tilt'
require 'middleman-core/renderers/redcarpet'
require_relative './markdown_preprocessors'

class MarkdownRenderer < Middleman::Renderers::MiddlemanRedcarpetHTML
  include MarkdownPreprocessors

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

  # based on http://blog.davydovanton.com/2016/05/14/middleman-add-title-anchors/
  def header(title, level)
    permalink = title.parameterize

    if headers.include? permalink
      permalink += '_1'
      permalink = permalink.succ while headers.include?(permalink)
    end

    headers << permalink

    anchor = %(<a name="#{permalink}" class="anchor" href="##{permalink}">#{anchor_svg}</a>)

    %(<h#{level} id="#{permalink}" class="hd">#{anchor}#{title}</h#{level}>)
  end

  def link(link, title, content)
    if content.start_with?('api::')
      _, project, path = content.split('::')
      link_to_api(project, path, target)
    elsif link['%{version}']
      super(link % { version: scope.version }, title, content)
    else
      super
    end
  end

  def link_to_api(project, path, target)
    klass = path.gsub('/', '::') if path

    if target.start_with?('#') || target.start_with?('.')
      content = "#{klass}#{target}"

      link(
        config.api_anchor_url_template % { project: project, path: path, anchor: anchor(target) },
        nil, content
      )
    else
      content = ['ROM', *klass, target].join('::')

      link(
        config.api_url_template % { project: project, path: path },
        nil, content
      )
    end
  end

  def config
    scope.config
  end

  def anchor_svg
    <<-eos
       <svg aria-hidden="true" height="16" width="16" version="1.1" viewBox="0 0 16 16">
       <path d="M4 9h1v1h-1c-1.5 0-3-1.69-3-3.5s1.55-3.5 3-3.5h4c1.45 0 3 1.69 3 3.5 0 1.41-0.91 2.72-2 3.25v-1.16c0.58-0.45 1-1.27 1-2.09 0-1.28-1.02-2.5-2-2.5H4c-0.98 0-2 1.22-2 2.5s1 2.5 2 2.5z m9-3h-1v1h1c1 0 2 1.22 2 2.5s-1.02 2.5-2 2.5H9c-0.98 0-2-1.22-2-2.5 0-0.83 0.42-1.64 1-2.09v-1.16c-1.09 0.53-2 1.84-2 3.25 0 1.81 1.55 3.5 3 3.5h4c1.45 0 3-1.69 3-3.5s-1.5-3.5-3-3.5z"></path>
       </svg>
     eos
  end

  def anchor(meth)
    if meth.start_with?('#')
      "#{meth[1..-1]}-instance_method"
    elsif meth.start_with?('.')
      "#{meth[1..-1]}-class_method"
    end
  end

  def headers
    @headers ||= []
  end
end
