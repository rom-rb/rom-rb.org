``` ruby
ROM.relation(:users) do

  def by_name(name)
    where(name: name)
  end

end
```
