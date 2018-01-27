# This is a monkey-patch to fix the problem with double-watching
# symlinked directories
WATCHED_PATHS = (
                  Dir["*"] -
                  %w(source node_modules vendor) +
                  Dir["source/*"] -
                  %w(source/current source/next source/learn source/guides)
                ). select {|f| File.directory?(f) }

class ::Middleman::SourceWatcher
  # The default source watcher implementation. Watches a directory on disk
  # and responds to events on changes.
  def listen!
    return if @disable_watcher || @listener || @waiting_for_existence

    config = {
      force_polling: @force_polling
    }

    config[:wait_for_delay] = @wait_for_delay.try(:to_f) || 0.5
    config[:latency] = @latency.to_f if @latency

    @listener = ::Listen.to(*WATCHED_PATHS, config, &method(:on_listener_change))

    @listener.start
  end
end

require_relative 'lib/site'

# Per-page layout changes:
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false
page '/', layout: 'layout'
page '/*/learn/*', layout: 'guide', data: { sidebar: '%{version}/learn/sidebar' }
page '/*/guides/*', layout: 'guide', data: { sidebar: '%{version}/guides/sidebar' }
page '/learn/*', layout: 'guide', data: { sidebar: '3.0/learn/sidebar' }
page '/guides/*', layout: 'guide', data: { sidebar: '3.0/guides/sidebar' }
page '/blog/*', data: { sidebar: 'blog/sidebar' }

Site.projects.each do |project|
  proxy "/api/#{project.name}/index.html", '/api/project.html', layout: 'api', locals: { project: project }, ignore: true
end

def next?
  ENV['NEXT'] == 'true'
end

if next?
  set :api_base_url, "http://www.rubydoc.info/#{next? ? 'github/rom-rb' : 'gems'}"
else
  set :api_base_url, "http://api.rom-rb.org"
end

set :api_url_template, "#{config.api_base_url}/%{project}/ROM/%{path}"
set :api_anchor_url_template, "#{config.api_base_url}/%{project}/ROM/%{path}#%{anchor}"

# Helpers
helpers do
  def nav_link_to(link_text, url, options = {})
    root = options.delete(:root)
    is_active = (!root && current_page.url.start_with?(url)) ||
                current_page.url == url
    options[:class] ||= ''
    options[:class] << '--is-active' if is_active
    link_to(link_text, url, options)
  end

  def learn_root_resource
    sitemap.find_resource_by_destination_path("#{ version }/learn/index.html")
  end

  def guides_root_resource
    sitemap.find_resource_by_destination_path("#{ version }/guides/index.html")
  end

  def sections_as_resources(resource)
    sections = resource.data.sections
    sections.map do |section|
      destination_path = resource.url + "#{ section }/index.html"
      sitemap.find_resource_by_destination_path(destination_path)
    end
  end

  def head_title
    current_page.data.title.nil? ? 'ROM' : "ROM - #{current_page.data.title}"
  end

  def og_url
    Site.development? ? current_page.url : "http://rom-rb.org#{current_page.url}"
  end

  def og_description
    if current_page.data.description.nil?
      "An open-source persistence and mapping toolkit for Ruby built for speed and simplicity."
    else
      current_page.data.description
    end
  end

  def og_image
    "http://rom-rb.org/images/logo--card.png"
  end

  def copyright
    "&copy; 2014-#{Time.now.year} Ruby Object Mapper."
  end

  def design_by
    url = 'https://github.com/angeloashmore'
    "Design by #{link_to '@angeloashmore', url}."
  end

  def logo_by
    url = 'https://github.com/kapowaz'
    "Logo by #{link_to '@kapowaz', url}."
  end

  def version
    current_path[%r{\A([\d\.]+|current|next)\/}, 1] || data.versions.fallback
  end

  def versions_match?(v1, v2)
    v1 == v2 || v1 == 'next' && v2 == data.versions.next
  end

  def version_variants
    next_vs = data.versions.show_next ? [["next", "next (#{ data.versions.next })"]] : []

    [*data.versions.core.map { |v| [v, v] },
     ["current", "current (#{ data.versions.current })"],
     *next_vs]
  end

  GH_NEW_ISSUE_URL = "https://github.com/rom-rb/rom-rb.org/issues/new?labels=%{labels}&assignees=%{assignees}&title=%{title}".freeze
  def feedback_link
    tokens = {
      title: "Feedback on #{URI.encode(head_title)}",
      labels: "feedback",
      assignees: "solnic"
    }

    link_to "Provide feedback!", GH_NEW_ISSUE_URL % tokens, class: "button"
  end

  GH_EDIT_FILE_URL = "https://github.com/rom-rb/rom-rb.org/blob/master%{current_path}".freeze
  def edit_file_link
    link_to "Edit on GitHub", GH_EDIT_FILE_URL % { current_path: current_source_file}, class: "button"
  end

  def current_source_file
    current_page.source_file.gsub(Dir.pwd, '')
  end

  def projects
    Site.projects
  end
end

# General configuration
set :build_dir, 'docs'
set :layout, 'content'
set :css_dir, 'assets/stylesheets'
set :js_dir, 'assets/javascripts'

# MD
require_relative 'lib/markdown_renderer'

set :markdown_engine, :redcarpet
set :markdown, renderer: MarkdownRenderer,
    tables: true,
    autolink: true,
    gh_blockcode: true,
    fenced_code_blocks: true,
    with_toc_data: true

set :disqus_embed_url, 'https://rom-rb-blog.disqus.com/embed.js'

activate :blog,
  prefix: 'blog',
  layout: 'blog_article',
  permalink: '{title}.html',
  paginate: true,
  tag_template: 'blog/tag.html'

activate :syntax, css_class: 'syntax'

activate :directory_indexes

activate :external_pipeline,
  name: :webpack,
  command: build? ? 'node ./node_modules/webpack/bin/webpack.js --bail' : 'node ./node_modules/webpack/bin/webpack.js --watch -d',
  source: 'tmp/dist',
  latency: 1

# Development-specific configuration
configure :development do
  activate :livereload
end

begin
  require 'pry-byebug'
rescue LoadError
end
