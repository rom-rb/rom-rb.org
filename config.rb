# frozen_string_literal: true

require 'pathname'

$LOAD_PATH.unshift(Pathname('./lib').realpath)

require 'rom/site'

# Per-page layout changes:
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false
page '/', layout: 'layout'
page '/learn/*', layout: 'guide', data: { sidebar: 'learn/sidebar' }
page '/guides/*', layout: 'guide', data: { sidebar: 'guides/sidebar' }
page '/blog/*', data: { sidebar: 'blog/sidebar' }

# Pre-docsite docs with global versions
page '/3.0/learn/*', layout: 'guide', data: { sidebar: '3.0/learn/sidebar' }
page '/3.0/guides/*', layout: 'guide', data: { sidebar: '3.0/guides/sidebar' }
page '/4.0/learn/*', layout: 'guide', data: { sidebar: '4.0/learn/sidebar' }
page '/4.0/guides/*', layout: 'guide', data: { sidebar: '4.0/guides/sidebar' }
page '/5.0/learn/*', layout: 'guide', data: { sidebar: '5.0/learn/sidebar' }
page '/5.0/guides/*', layout: 'guide', data: { sidebar: '5.0/guides/sidebar' }

Middleman::Docsite.projects.each do |project|
  proxy "/api/#{project.name}/index.html", '/api/project.html', layout: 'api', locals: { project: project }, ignore: true
end

Middleman::Docsite.projects.select(&:versioned?).each do |project|
  proxy(
    "/learn/#{project.slug}/index.html",
    '/project-index-redirect.html',
    locals: { path: project.latest_path },
    layout: false,
    ignore: true
  )
end

set :api_base_url, 'https://api.rom-rb.org'
set :api_url_template, "#{config.api_base_url}/%{project}/ROM/%{path}"
set :api_anchor_url_template, "#{config.api_base_url}/%{project}/ROM/%{path}#%{anchor}"

# Helpers
helpers do
  def projects
    docsite.projects
  end

  def docsite_projects
    projects.select(&:versioned?)
  end

  def docsite
    Middleman::Docsite
  end

  def nav_link_to(link_text, url, options = {})
    root = options.delete(:root)
    is_active = (!root && current_page.url.start_with?(url)) ||
                current_page.url == url
    options[:class] ||= ''
    options[:class] << '--is-active' if is_active
    link_to(link_text, url, options)
  end

  def learn_root_resources
    resources =
      non_project_learn_resources
        .map { |r| [r, r.data.position] } +
      project_learn_resources
        .map.with_index { |r, i| [r, i + 1] }

    resources.sort_by(&:last).map(&:first)
  end

  def project_learn_resources
    docsite_projects
      .map { |project|
        sitemap
          .find_resource_by_destination_path(
            "learn/#{project.slug}/#{project.latest_version}/index.html"
          )
      }
  end

  def non_project_learn_resources
    Dir[docsite.source_dir.join("*")]
      .map(&method(:Pathname))
      .reject(&:file?)
      .reject { |path| projects.map(&:slug).include?(path.basename.to_s) }
      .map { |path|
        sitemap
          .find_resource_by_destination_path("learn/#{path.basename}/index.html")
      }
  end

  def legacy_learn_root_resource
    sitemap.find_resource_by_destination_path("#{version}/learn/index.html")
  end

  def legacy_guides_root_resource
    sitemap.find_resource_by_destination_path("#{version}/guides/index.html")
  end

  def guides_root_resource
    sitemap.find_resource_by_destination_path("guides/index.html")
  end

  def sections_as_resources(resource)
    sections = resource.data.sections
    sections.map do |section|
      destination_path = resource.url + "#{section}/index.html"
      sitemap.find_resource_by_destination_path(destination_path)
    end
  end

  def head_title
    current_page.data.title.nil? ? 'ROM' : "ROM - #{current_page.data.title}"
  end

  def guide_title
    [current_page.data.chapter, current_page.data.title].compact.join(' &raquo; ')
  end

  def og_url
    Middleman::Docsite.development? ? current_page.url : "http://rom-rb.org#{current_page.url}"
  end

  def og_description
    if current_page.data.description.nil?
      'An open-source persistence and mapping toolkit for Ruby built for speed and simplicity.'
    else
      current_page.data.description
    end
  end

  def og_image
    'http://rom-rb.org/images/logo--card.png'
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
    current_path[%r{(\d+\.\d+)}] || 'main'
  end

  def versions_match?(v1, v2)
    v1 == v2
  end

  def version_variants
    ["3.0", "4.0", "5.0"]
  end

  GH_NEW_ISSUE_URL = 'https://github.com/rom-rb/rom-rb.org/issues/new?labels=%{labels}&assignees=%{assignees}&title=%{title}'
  def feedback_link
    tokens = {
      title: "Feedback on #{URI.encode(head_title)}",
      labels: 'feedback',
      assignees: 'solnic'
    }

    link_to 'Provide feedback!', GH_NEW_ISSUE_URL % tokens, class: 'button'
  end

  def current_branch
    @current_branch ||= `git branch`.chomp.split("\n").map(&:strip).grep(/^\*/)[0].split.last
  end

  GH_EDIT_FILE_URL = 'https://github.com/rom-rb/rom-rb.org/blob/%{branch}%{current_path}'
  def edit_file_link
    match = current_source_file[%r[(\w+)/(\d+\.\d+)]]

    project_slug, version = match ? match.split('/') : []

    url =
      if project_slug != "source" && version
        project = docsite_projects.detect { |p| p.slug.eql?(project_slug) }

        project.file_url(version, current_source_file)
      else
        GH_EDIT_FILE_URL % { branch: current_branch, current_path: current_source_file }
      end

    link_to 'Edit on GitHub', url, class: 'button'
  end

  def current_source_file
    current_page.source_file.gsub(Dir.pwd, '')
  end
end

# General configuration
set :build_dir, 'docs'
set :layout, 'content'
set :css_dir, 'assets/stylesheets'
set :js_dir, 'assets/javascripts'

set :markdown_engine, :redcarpet
set :markdown, renderer: ROM::Site::Markdown::Renderer,
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

begin
  require 'pry-byebug'
rescue LoadError
end
