require 'yaml'

module Site
  def self.projects
    @projects ||= YAML.load_file(data_path.join('projects.yaml')).map(&Project.method(:new))
  end

  def self.data_path
    root.join('data')
  end

  def self.root
    @root ||= Pathname(__dir__).join('..')
  end

  def self.development?
    Middleman::Application.config.environment == :development
  end

  class Project
    attr_reader :attrs

    def initialize(attrs)
      @attrs = attrs
    end

    def name
      attrs['name']
    end
    alias_method :to_s, :name

    def github_url
      "https://github.com/rom-rb/#{name}"
    end

    def rubygems_url
      "https://rubygems.org/gems/#{name}"
    end

    def version_badge
      "https://img.shields.io/gem/v/#{name}.svg?style=flat"
    end

    def ci_badge
      "https://img.shields.io/travis/rom-rb/#{name}/master.svg?style=flat"
    end

    def codeclimate_url
      "https://codeclimate.com/github/rom-rb/#{name}"
    end

    def codeclimate_badge
      "https://codeclimate.com/github/rom-rb/#{name}/badges/gpa.svg"
    end

    def coverage_badge
      "https://codeclimate.com/github/rom-rb/#{name}/badges/coverage.svg"
    end

    def inch_url
      "http://inch-ci.org/github/rom-rb/#{name}"
    end

    def inch_badge
      "http://inch-ci.org/github/rom-rb/#{name}.svg?branch=master&style=flat"
    end

    def api_url
      "#{api_host_url}/#{name}"
    end

    def api_host_url
      Site.development? ? "http://localhost:4000/docs" : "https://api.rom-rb.org"
    end
  end
end
