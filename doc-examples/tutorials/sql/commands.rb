require_relative 'setup'

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
