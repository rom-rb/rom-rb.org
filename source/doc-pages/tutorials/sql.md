### Setup

To configure database connection you pass in a hash with connection identifiers
and URIs. Any URI that's supported by Sequel can be used here:

``` ruby
setup = ROM.setup(my_db: 'sqlite::memory')
```

### Migrations

Sequel migration interface is available:

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
methods and association definitions:

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
