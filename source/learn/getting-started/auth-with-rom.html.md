
---
chapter: Simple authentication with ROM and Rails
title: Block Style Setup
---

## Initial setup

First of all, let's add following gems to the Gemfile:

```ruby
gem 'rom-rails'
gem 'rom-sql'
gem 'rom-repository'
gem 'rom'
gem 'warden'
gem 'bcrypt'
gem 'sqlite3'
```

Now we will need to add configuration for rom to work. In this example we are going to use SQLite3 to store our data:

```ruby
ROM::Rails::Railtie.configure do |config|
  config.gateways[:default] = [:sql, "sqlite://db/dev.db"]
end
```
After this, we will need to add ROM rake tasks in our Procfile

```ruby
require 'rom/sql/rake_task'
```

When this is done, let's generate a migration that adds users table to our database:

The migration should look as follows:
```ruby
ROM::SQL.migration do
  change do
    create_table :users do
      primary_key :id
      column :email, String, null: false, unique: true
      column :encrypted_password, String, null: false
    end
  end
end
```
We want emails to be unique, and both password and email fields to not be NULL.

Let's run our migration task:
```

```

Once that is done, we can start working on our repositories and rom components. Let's add schema file first in `app/relations/users.rb`:
```ruby
class Users < ROM::Relation[:sql]
end
```
After that, let's add repository that will do all the heavy lifting for us:
```ruby
include BCrypt

class UsersRepo < ROM::Repository[:users]
  def find_by_id(id)
    users.where(id: id).one
  end

  def authenticate(email, password)
    user = users.where(email: email).one
    if user && Password.new(user.encrypted_password) == password
      user
    else
      nil
    end
  end

  def create(email, password)
    users.insert(email: email, encrypted_password: Password.create(password))
  end
end
```
In this repo we will have three methods. One that finds a user by id, which will be used in warden later on. Another is authenticate, that will take email and password and will return user if it is present and password is correct. The third one is for creating user with encrypted password.

Now that this is done, we can implement warden password strategy. In initializers you can put the following code:
```ruby
Rails.application.config.middleware.use Warden::Manager do |manager|
  manager.default_strategies :password
end

Warden::Manager.serialize_into_session do |user|
  user.id
end

Warden::Manager.serialize_from_session do |id|
  UsersRepo.new(ROM.env).find_by_id(id)
end

Warden::Strategies.add(:password) do
  def authenticate!
    user = UsersRepo.new(ROM.env).authenticate(params["session"]["email"], params["session"]["password"])
    if user
      success! user
    else
      fail! "Invalid email or password"
    end
  end
end
```
In first block we define that we want to use password strategy for authentication. 
In the next few lines we are identifying how we want to serialize and deserialize user from and to session. 
In the last part we define what the autentication for the user will look like and call appropriate warden methods.


Let's add a controller for handling sessions with a new session form, create session action and destory session action.
```ruby
class UserSessionsController < ApplicationController
  def new
  end

  def create
    user = env['warden'].authenticate
    if user
      redirect_to new_user_session_path, notice: "Logged in!"
    else
      flash[:alert] = env['warden'].message
      render "new"
    end
  end

  def destroy
    env['warden'].logout
    redirect_to new_user_session_path, notice: "Logged out!"
  end
end
```

The next step in line is to add user creation. Please take a note that user creation has no validations in place, so don't put this code in production.

```ruby
class UsersController < ApplicationController
  def new
  end

  def create
    UsersRepo.new(ROM.env).create(params[:user][:email], params[:user][:password])
    redirect_to new_user_session_path, notice: "User created. Now you can log in!"
  end
end
```

There is one additional step that we need to take and define a `current_user` helper method so it can be used in views and elseware.
```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :current_user

  def current_user
    env["warden"].user
  end
end
```

After we are done with controllers, we need to map them to routes:
```ruby
Rails.application.routes.draw do
  resources :users, only: [:new, :create]
  resources :user_sessions, only: [:new, :create]
  match 'user_sessions/destroy' => "user_sessions#destroy", via: :delete, as: :destroy_user_sessions
end
```
Let's create a header partial that can be included in all our view files:
```ruby
<% if current_user %>
  Hello <%= current_user.email %>!
  <%= link_to "Log out", destroy_user_sessions_path, method: :delete %>
<% else %>
  Hello guest!
  <%= link_to "Sign up", new_user_path %>
<% end %>
<% flash.each do |key, value| %>
  <div class="alert alert-<%= key %>"><%= value %></div>
<% end %>
```

Create a login form:
```ruby
<%= render partial: "layouts/header" %>
<h1>Log in</h1>

<div class="row">
  <div class="col-md-6 col-md-offset-3">
    <%= form_for(:session, url: user_sessions_path) do |f| %>

      <%= f.label :email %>
      <%= f.email_field :email, class: 'form-control' %>

      <%= f.label :password %>
      <%= f.password_field :password, class: 'form-control' %>

      <%= f.submit "Log in", class: "btn btn-primary" %>
    <% end %>

  </div>
</div>
```
A sign up form:
```ruby
<%= render partial: "layouts/header" %>

<h1>Sign up</h1>

<div class="row">
  <div class="col-md-6 col-md-offset-3">
    <%= form_for(:user, url: users_path) do |f| %>

      <%= f.label :email %>
      <%= f.email_field :email, class: 'form-control' %>

      <%= f.label :password %>
      <%= f.password_field :password, class: 'form-control' %>

      <%= f.submit "Log in", class: "btn btn-primary" %>
    <% end %>

  </div>
</div>
```

And we are done! Check out `localhost:3000/user_sessions/new` to have ability to log in or to navigate to sign up form!

