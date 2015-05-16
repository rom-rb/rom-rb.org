``` ruby
class CreateUser < ROM::Commands::Create[:sql]
  relation :users
  register_as :create
  input NewUserInput
  validator NewUserValidator
  result :one
end
```
