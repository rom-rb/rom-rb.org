``` ruby
class UserEntityMapper < ROM::Mapper
  relation :users
  register_as :entity
  model User
  attribute :id
  attribute :name
end
```
