gem "rom", github: 'rom-rb/rom', branch: 'master'
gem "rom-sql", github: 'rom-rb/rom-sql', branch: 'master'
gem "rom-rails", github: 'rom-rb/rom-rails', branch: 'master'

gem_group(:test) do
  gem "rspec"
  gem "rspec-rails"
  gem "capybara"
  gem "database_cleaner"
  gem "spring-commands-rspec"
end

application "require 'rom-rails'"

run 'bundle'

generate "rspec:install"

gsub_file "spec/rails_helper.rb",
  "config.use_transactional_fixtures = true",
  "config.use_transactional_fixtures = false"

insert_into_file "spec/rails_helper.rb",
  after: "config.use_transactional_fixtures = false\n" do
  <<-CONTENT

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
  CONTENT
end

generate "migration", "create_tasks", "title:string"

generate "rom:relation", "tasks"
generate "rom:mapper", "tasks"
generate "rom:commands", "tasks"

route "resources :tasks"

rake "db:migrate"

file "spec/features/tasks_spec.rb" do
  <<-CONTENT.strip_heredoc
    require 'rails_helper'

    feature 'Tasks' do
      # examples...
    end
  CONTENT
end

file "spec/relations/tasks_spec.rb" do
  <<-CONTENT.strip_heredoc
    require 'rails_helper'

    describe 'Tasks relation' do
      # examples...
    end
  CONTENT
end

file "spec/fixtures/tasks.yml" do
  <<-CONTENT.strip_heredoc
    one:
      id: 1
      title: 'Task One'
    two:
      id: 2
      title: 'Task Two'
  CONTENT
end
