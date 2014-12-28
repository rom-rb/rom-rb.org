require_relative 'setup'

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

puts rom.read(:users).with_tasks.to_a.inspect
# => [#<Entities::User:0x007f88799149f8 @id=1, @name="Jane", @tasks=[#<Entities::UserTask:0x007f8879914ae8 @title="Have fun">]>]

puts rom.read(:tasks).with_user.to_a.inspect
# => [#<Entities::Task:0x007f887a3d11c0 @id=1, @user_id=1, @title="Have fun", @priority=1, @user=#<Entities::TaskUser:0x007f887a3d13f0 @name="Jane">>]
