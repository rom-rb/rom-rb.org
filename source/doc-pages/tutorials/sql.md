### Setup

To configure database connection you pass in a hash with connection identifiers
and URIs. Any URI that's supported by Sequel can be used here:

``` ruby
setup = ROM.setup(my_db: 'sqlite::memory')
```

### Migrations

For schema migrations you can use Sequel's
[Migration API](http://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html).

``` ruby
setup.sqlite.connection.create_table(:users) do
  primary_key :id
  String :name
  Boolean :admin
end

setup.sqlite.connection.create_table(:tasks) do
  primary_key :id
  Integer :user_id
  String :title
  Integer :priority
end
```

### Relations

You can define relations for every database table and extend them with custom
methods and association definitions.

[Sequel Dataset API](http://sequel.jeremyevans.net/rdoc/files/doc/dataset_basics_rdoc.html)
is available inside relations.

``` ruby
ROM.relation(:users) do

  def by_name(name)
    all.where(name: name)
  end

  def all
    order(:users__name, :users__email, :users__id)
  end

end

ROM.relation(:tasks) do

  def high_priority
    all.where { priority > 3 }
  end

  def all
    order(:tasks__title, :tasks__id)
  end

end

rom = ROM.finalize.env

rom.read(:users).by_name('Jane')
rom.read(:tasks).high_priority
```

### Mapping joins to aggregates

ROM doesn't have a relationship concept like in ActiveRecord or Sequel. Instead
it provides a convenient interface for building joined relations that can be
mapped to [aggregate objects](http://martinfowler.com/bliki/Aggregate.html).

There's no lazy-loading, eager-loading or any other magic happening behind the
scenes. You're in full control of how data are fetched from the database and it's
an explicit operation.

Sequel's association DSL is available in relation definitions which enables
`association_join` interface inside relations. To map joined results to
aggregate objects `wrap` and `group` mapping transformation can be used

``` ruby
ROM.relation(:users) do

  one_to_many :tasks, key: :user_id

  def with_tasks
    association_join(:tasks, select: [:title])
  end

end

ROM.relation(:tasks) do

  many_to_one :users, key: :user_id

  def with_user
    association_join(:users, select: [:name])
  end

end

module Entities; end

ROM.mappers do
  define(:users) do
    model name: 'Entities::User'

    group :tasks do
      model name: 'Entities::UserTask'
      attribute :title
    end
  end

  define(:tasks) do
    model name: 'Entities::Task'

    wrap :user do
      model name: 'Entities::TaskUser'
      attribute :name
    end
  end
end

rom = ROM.finalize.env

rom.read(:users).with_tasks.to_a
# => [#<Entities::User:0x007f88799149f8 @id=1, @name="Jane", @tasks=[#<Entities::UserTask:0x007f8879914ae8 @title="Have fun">]>]

rom.read(:tasks).with_user.to_a
# => [#<Entities::Task:0x007f887a3d11c0 @id=1, @user_id=1, @title="Have fun", @priority=1, @user=#<Entities::TaskUser:0x007f887a3d13f0 @name="Jane">>]
```

### Commands

To create, update and delete tuples you can define commands:

``` ruby
ROM.relation(:users) do

  def by_id(id)
    where(id: id)
  end

  def by_name(name)
    where(name: name)
  end

end

ROM.commands(:users) do
  define(:create) do
    result :one
  end

  define(:update) do
    result :one
  end

  define(:delete) do
    result :many
  end
end

rom = ROM.finalize.env

user_commands = rom.command(:users)

result = user_commands.try { create(name: 'Jade') }

puts result.inspect
# => #<ROM::Result::Success:0x007fde43188200 @value={:id=>2, :name=>"Jade"}>

result = user_commands.try { update(:by_id, 2).set(name: 'Jade Doe') }

puts result.inspect
# => #<ROM::Result::Success:0x007fcf214a8b78 @value={:id=>1, :name=>"Jane Doe"}>

result = user_commands.try { delete(:by_name, 'Jade Doe').execute }

puts result.inspect
# => #<ROM::Result::Success:0x007fb07a15cc00 @value=[{:id=>2, :name=>"Jade Doe"}]>
```

### Handling input, validation and errors

When defining commands you can provide external input handlers and validators:

``` ruby
require 'virtus'

ROM.relation(:users) do

  def by_id(id)
    where(id: id)
  end

  def by_name(name)
    where(name: name)
  end

end

class NewUserInput
  include Virtus.model

  attribute :name, String

  def self.[](input)
    new(input)
  end
end

class NewUserValidator
  InvalidInputError = Class.new(ROM::CommandError)

  # Required by ROM
  def self.call(input)
    errors = []
    errors << "name cannot be blank" if input.name == ''
    raise InvalidInputError, errors if errors.any?
  end
end

ROM.commands(:users) do
  define(:create) do
    input NewUserInput
    validator NewUserValidator
    result :one
  end
end

rom = ROM.finalize.env

user_commands = rom.command(:users)

result = user_commands.try { create(name: '') }

puts result.inspect
# => #<ROM::Result::Failure:0x007f91b38f95e8 @error=#<NewUserValidator::InvalidInputError: ["name cannot be blank"]>>
```
