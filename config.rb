Encoding.default_internal = "utf-8"

require 'slim'
require 'builder'

set :site_url, 'http://rom-rb.org'
set :page_title, 'Ruby Object Mapper'
set :twitter_handle, '@rom_rb'

set :markdown_engine, :redcarpet
set :markdown, fenced_code_blocks: true, smartypants: true

# blog config
activate :blog do |blog|
  blog.prefix = 'blog'
  blog.layout = 'blog'
  blog.permalink = '{year}/{month}/{day}/{title}'
  blog.paginate = true
end

page 'blog/*', layout: 'blog_article'
page 'blog/feed.xml', layout: false

configure :build do
  activate :minify_javascript
  activate :relative_assets
end

# syntax stuff
activate :syntax

set :css_dir,    'stylesheets'
set :js_dir,     'javascripts'
set :images_dir, 'images'

activate :livereload
activate :directory_indexes

helpers do

  def nav_heading(slug, title)
    nav_link(slug, title, "nav-heading")
  end

  def nav_link(slug, title, class_names = [])
    current = current_page.data.slug

    class_names = Array(class_names)
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

  def article_permalink(article)
    date  = article.date
    parts = ['/blog']

    parts << date.year
    parts << date.month.to_s.rjust(2, '0')
    parts << date.day.to_s.rjust(2, '0')
    parts << article.slug

    parts.join('/')
  end

  def article_url(article)
    "#{config.site_url}#{article_permalink(article)}"
  end

  def page_title
    if is_blog_article?
      "ROM &raquo; Blog &raquo; #{current_article.title}"
    else
      if yield_content(:page_title)
        "ROM &raquo; #{yield_content(:page_title)}"
      else
        "ROM &raquo; #{data.page.title}"
      end
    end
  end

  def twitter_page_title
    "#{page_title} via #{config.twitter_handle}"
  end
end
