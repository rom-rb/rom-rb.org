---
chapter: Testing
title: Factories
---

When using ROM, you will need to test your code, and testing your code implies generating entities and use Factories to
create records on your database. To do all of that, you can use `rom-factory`, which provides more or less same 
functionnalities as `FactoryBot`.

### Install RomFactory

In your gemfile:

```ruby
gem 'rom-factory'
```

### Setup ROMFactory

Then on your spec root file (like `spec_helper`), you have to initialize your factory:

```ruby
# Build database configuration
db_config = { 
  adapter: 'mysql2',
  database: 'db_name',
  host: 'database.host.io',
  username: 'username',
  password: 'password',
  port: 3306
}

# Init your ROM container
rom = ROM.container(:sql, db_config)do |config|
        # Register ROM related files, especially Relations
        config.auto_registration('../app/') # if your sources are in app folder
      end

# Declare your factory
YourFactory = ROM::Factory.configure do |config|
  config.rom = rom
end

# Load your factories' files
Dir[App.root + '/spec/factories/**/*.rb'].each { |f| require f } # if you plan to put your factory files `spec/factories`
```

### Define your factory

Then you can define your factories:

```ruby
YourFactory.define(:user) do |f|
  f.sequence(:name) { |n| "User#{n}" }
  f.website 'http://personal.website'
  f.some_integer 42
  f.created_at Time.now.utc
end
```

You can define multiple builders on the same factory.
In this example, the relation `users` (ie builder name pluralized) must exist in your ROM::RelationRegistry`.

### Use your factory

In your tests, you can either get an instance from your factory only in memory, or in memory but that has been 
persisted on your database.

Let's suppose that  `UserRepo` is your Users' repository and it has a relation to `users` SQL table. 

```ruby
user1 = YourFactory[:user]
p user1
#=> #<ROM::Struct::User id=84 name="User1" website="http://personnal.website" some_integer=42 created_at=2019-04-02 08:50:34 +0000>

p UserRepo.users.by_pk(user1.id).one
#=> #<ROM::Struct::User id=84 name="User1" website="http://personnal.website" some_integer=42 created_at=2019-04-02 08:50:34 +0000>

user2 = YourFactory.structs[:user]
p user2
#=> #<ROM::Struct::User id=85 name="User2" website="http://personnal.website" some_integer=42 created_at=2019-04-02 08:50:46 +0000>

p UserRepo.users.by_pk(user2.id).one
#=> nil

user3 = YourFactory.structs[:user, name: "toto", website: nil]
p user3
#=> #<ROM::Struct::User id=85 name="toto" website=nil some_integer=42 created_at=2019-04-02 08:51:20 +0000>
```

### Going further

#### Associations

RomFactory supports associations that you declared in your Relations.
```ruby
YourFactory.define(:user) do |f|
  # this will use :team builder to create a team for a user
  f.association(:team)

  # this will create 2 posts for a user using :post builder
  f.association(:posts, count: 2)
end
```

#### Faker

ROMFactory comes with Faker gem:

```ruby
YourFactory.define(:foo) do |f|
  f.bar { fake(:number, :between, 10, 100) }
end
```

#### Traits

ROMFactory supports traits:

```ruby
YourFactory.define(:user) do |f|
  f.registered true

  f.trait :not_registered do |t|
    t.registered false
  end
end

p YourFactory[:user, :not_registered]
#=> #<ROM::Struct::User id=130 registered=false>
```

### Inheritance
You can extend existing builders, see [Rom Factory annoncement](https://rom-rb.org/blog/announcing-rom-factory/) for an
example.


### Read more:
* [Rom Factory annoncement](https://rom-rb.org/blog/announcing-rom-factory/)
* [Rom Factory repository](https://github.com/rom-rb/rom-factory/)
