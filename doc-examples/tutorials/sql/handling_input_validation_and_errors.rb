require_relative 'setup'
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
