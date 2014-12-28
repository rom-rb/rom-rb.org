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
