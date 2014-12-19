require 'rom-sql'

# Setup
setup = ROM.setup(sqlite: 'sqlite::memory')

conn = setup.sqlite.connection
conn.drop_table?(:users)
conn.drop_table?(:tasks)

# Migrations
setup.sqlite.connection.create_table(:users) do
  primary_key :id
  String :name
end

setup.sqlite.connection.create_table(:tasks) do
  primary_key :id
  Integer :user_id
  String :title
  Integer :priority
end

conn[:users].insert(id: 1, name: 'Jane')
conn[:tasks].insert(user_id: 1, title: 'Have fun', priority: 1)

ROM.relation(:users) do

  one_to_many :tasks, key: :user_id

  def with_tasks
    association_left_join(:tasks, select: [:title])
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

puts rom.read(:users).with_tasks.to_a
# => [#<Entities::User:0x007f88799149f8 @id=1, @name="Jane", @tasks=[#<Entities::UserTask:0x007f8879914ae8 @title="Have fun">]>]

rom.read(:tasks).with_user.to_a
# => [#<Entities::Task:0x007f887a3d11c0 @id=1, @user_id=1, @title="Have fun", @priority=1, @user=#<Entities::TaskUser:0x007f887a3d13f0 @name="Jane">>]
