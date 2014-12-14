Encoding.default_internal = "utf-8"

require 'slim'

activate :livereload
activate :directory_indexes

# syntax stuff
activate :syntax

set :markdown_engine, :redcarpet
set :markdown, fenced_code_blocks: true, smartypants: true

set :css_dir,    'stylesheets'
set :js_dir,     'javascripts'
set :images_dir, 'images'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  # activate :minify_css

  # Minify Javascript on build
  activate :minify_javascript

  # Enable cache buster
  # activate :cache_buster

  # Use relative URLs
  activate :relative_assets

  # Compress PNGs after build
  # First: gem install middleman-smusher
  # require "middleman-smusher"
  # activate :smusher

  # Or use a different image path
  # set :http_path, "/Content/images/"
end

helpers do

  def nav_link(slug, title)
    current = current_page.data.slug

    class_names = []
    class_names << 'active' if slug == current

    content_tag(:li, class: class_names.join(' ')) do
      link_to(title, slug, class: class_names.join(' '))
    end
  end

  def introduction_layout(&block)
    partial "layouts/introduction", locals: { content: capture_html(&block) }
  end

  def tutorials_layout(&block)
    partial "layouts/tutorials", locals: { content: capture_html(&block) }
  end

  DOC_PAGES_ROOT = 'https://github.com/rom-rb/rom-rb.org/tree/master/source/doc-pages%{slug}.md'
  GEMS = %w(rom rom-sql rom-mongo rom-rails)

  def edit_article_link(title = 'Edit')
    slug = current_page.data.slug
    link_to title, DOC_PAGES_ROOT % { slug: slug }
  end

  def api_docs_link(gem)
    link_to gem, "http://www.rubydoc.info/gems/#{gem}"
  end

  def api_docs_nav
    html = ""

    html << link_to("API Docs <span class='caret'/>", "#",
                    class: "dropdown-toggle",
                    role: "button", data: { toggle: "dropdown" })

    html << content_tag(:ul, class: "dropdown-menu", role: "menu") do
      GEMS.map { |name| content_tag(:li, api_docs_link(name)) }.join
    end

    html
  end

end
