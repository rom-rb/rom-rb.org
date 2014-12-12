``` ruby
ROM.commands(:users) do
  define(:create) do
    input NewUserInput
    validator NewUserValidator
    result :one
  end
end
```
