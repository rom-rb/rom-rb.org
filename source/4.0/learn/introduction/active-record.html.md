---
chapter: Introduction
title: Compared to ActiveRecord
---

$TOC
  1. [Models vs Relations](#models-vs-relations)
  2. [Queries](#queries)
  3. [Associations](#associations)
  4. [Persistence](#persistence)
  6. [Validation](#validation)
  7. [Where ROM Shines](#where-rom-shines)
$TOC

Rails ActiveRecord is the most popular persistence
framework in ruby land. Deployed inside the majority of rails applications
across the web, it provides APIs for quick and simple data access making it a
great solution for constructing CRUD style applications.

Our intention for this guide is to act as a primer for anyone familiar with
Rails' ActiveRecord and looking for a quick start guide. Examples in each set will
show how ActiveRecord accomplishes each task followed by an example
with the equivalent using ROM.

All ROM examples are based on `rom-sql` which is an adapter needed to use SQL
databases with ROM. Information on installing and configuring rom-sql for your
database can be found in the
[SQL](/%{version}/learn/sql) guide.

^INFO
  Examples below assume a configured environment for each
  framework. For ROM examples this means an initialized `ROM::Container` with
  each component registered.

  For information on how to configure a ROM environment see either
  [Setup DSL](/%{version}/learn/getting-started/setup-sql)
  or
  [Rails Setup](/%{version}/learn/getting-started/rails-setup)
  guides.
^

^INFO
  Both frameworks have many similar APIs but philosophically they are
  completely different. In this guide, we attempt to highlight these differences
  and provide context for why we chose a different path. That is not to say ROM
  is better than ActiveRecord or vise-versa, it's that they're different and
  each has its own strengths and weaknesses. 
^

## Models vs Relations

The first difference is ROM doesn't really have a concept of models. ROM objects
are instantiated by the mappers and have no knowledge about persistence. You can
map to whatever structure you want and in common use-cases you can use
relations to automatically map query results to simple struct-like objects.

The closest implementation to models would be `ROM::Struct`, which is
essentially a data object with attribute readers, coercible to a hash.
More on ROM Structs later.

<h4 class="text-center">Active Record</h4>

```ruby
class User < ApplicationRecord
end
```

<h4 class="text-center">ROM</h4>

```ruby
class Users < ROM::Relation[:sql]
  schema(infer: true)
end
```

As you can see, ActiveRecord and ROM have similar boilerplate and as this guide
progresses both will use similar APIs to accomplish the same tasks. The
difference between models and relations lies within their scope and intended
purposes. ActiveRecord models represent an all encompassing thing that contains
*state*, *behavior*, *identity*, *persistence logic* and *validations* whereas
ROM relations describe how data is connected to other relations and provides
stateless APIs for applying *views* of that data on demand.

### Models vs ROM Structs

The most direct analog to ActiveRecord models in ROM is a `ROM::Struct`. ROM
structs provide a quick method for adding behavior to mapped data returned from
a relation. A custom type or plain hash can also be used instead, but ROM
structs offer a fast alternative without having to write a lot of boilerplate.

<h4 class="text-center">Active Record</h4>

```ruby
class User < ApplicationRecord
  def first_name
    name.split(' ').first
  end

  def last_name
    name.split(' ').last
  end
end

user = User.first
#> #<User id: 1, name: "Jane Doe">

user.first_name
#> "Jane"

user.last_name
#> "Doe"
```

<h4 class="text-center">ROM</h4>

```ruby
class Users < ROM::Relation[:sql]
  struct_namespace Entities

  schema(infer: true)
end

module Entities
  class User < ROM::Struct
    def first_name
      name.split(' ').first
    end

    def last_name
      name.split(' ').last
    end
  end
end

user = users_relation.first
#> #<Entitites::User id=1 name="Jane Doe">

user.first_name
#> "Jane"

user.last_name
#> "Doe"
```

For a brief overview and links to more in-depth information about relations see
the Relations section in our
[Core Concepts](/%{version}/learn/getting-started/core-concepts#relations)
guide.

## Queries

### Basic Queries

Once you have a relation, it becomes almost trivial to start querying for
information in a similar fashion as ActiveRecord. A basic example below:

<h4 class="text-center">Active Record</h4>

```ruby
User.where(name: "Jane").first
#> #<User id: 1, name: "Jane">
```

<h4 class="text-center">ROM</h4>
```ruby
users_relation.where(name: "Jane").first
#<ROM::Struct::User id=1 name="Jane">
```

### Query Subset of Data

<h4 class="text-center">Active Record</h4>
```ruby
User.select("name").where(name: name).first

#> #<User id: nil, name: "Jane">
```


<h4 class="text-center">ROM</h4>
```ruby
users_relation.select(:name).where(name: name).one

#> #<ROM::Struct::User name="Jane">
```

### Query with Complex Conditions

<h4 class="text-center">Active Record</h4>
```ruby
User.where("admin IS ? OR moderator IS ?", true, true)
```


<h4 class="text-center">ROM</h4>
```ruby
users_relation.where { admin.is(true) | (moderator.is(true)) }
```

For several SQL keywords, such as `select` & `where`, ROM provides a DSL for
blocks. The benefit is the ability to use any SQL functions supported by your
database. 

## Associations

Similar to ActiveRecord, ROM uses associations as a means of describing the
interconnections between data. 

<!--
  NOTE: Expand on this section with examples on how associations work
        and how to configure them properly.
-->

### Join Query

<h4 class="text-center">Active Record</h4>
```ruby
Article.joins(:users)
```

<h4 class="text-center">ROM</h4>
```ruby
articles_relation.join(:users)
```

Obviously the join interface for both frameworks can support different configurations
to handle different types of joins, however this example illustrates that other than
a minor name change, in the majority of use-cases they will act the same.

## Persistence

### Creating Simple Objects

<h4 class="text-center">Active Record</h4>
```ruby
User.create(name: "Jane")
#> #<User id: 1, name: "Jane">
```


<h4 class="text-center">ROM</h4>
```ruby
users_relation
  .changeset(:create, name: "Jane")
  .commit
#> #<ROM::Struct::User id=1 name="Jane">
```

Changesets are an abstraction created over commands which are what actually
manipulate stored records. They are preferred over commands due to additional
functionality they provide. 


### Updating Simple Objects

<h4 class="text-center">Active Record</h4>
```ruby
user = User.find_by(name: "Jane")
user.update(name: "Jane Doe")

#> #<User id=1 name="Jane Doe">
```


<h4 class="text-center">ROM</h4>
```ruby
users_relation
  .where(name: "Jane")
  .changeset(:update, name: "Jane Doe")
  .commit

#> #<ROM::Struct::User id=1 name="Jane Doe">
```

It should be noted that updating a record in ActiveRecord generally requires 
that record to first be loaded then updated then committed. We view this as
a bad practice as it leads to more round trips from the database and entities
that are initialized in an invalid state. If a developer is sufficiently
validating data at the boundaries of the application then updating or creating
a record without loading it should be no problem and in fact preferable.

<!-- ### Create Nested Objects

<h4 class="text-center">Active Record</h4>
```ruby
class User < ApplicationRecord
  has_many :tasks

  accepts_nested_attributes_for :tasks
end

class Task < ApplicationRecord
  belongs_to :user
end

user_data = {
  name: "Joe",
  tasks_attributes: [ {title: "Task 1"} ]
}

user = User.create(user_data)
```

%
  REVIEW NOTES: The following example is broken ensure it works before
  publishing.
%

<h4 class="text-center">ROM</h4>
```ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks
    end
  end
end

class Tasks < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      belongs_to :user
    end
  end
end

user_data = {
  name: "Joe",
  tasks: [ {title: "Task 1"} ]
}

users_relation
  .combine(:tasks)
  .changeset(:create, user_data)
  .commit

#> #<ROM::Struct::User id=4 name="Joe" tasks= [
#>  #<ROM::Struct::Task id=3 user_id=4 title="Task 1">
#> ]>
```

Instead of requiring changes to a relation to handle nested attributes, a ROM
relation can leverage its existing associations to determine nested input and
changesets can wire up any ids needed by sub records.

This is all possible without a tool like `accepts_nested_attributes_for` because
ROM relations are not expected to handle raw input from a multitude of external
sources and they're not expected to handle an object that could be in any random
state at any time. Changesets utilize relation schemas to be sure that each attribute is
the correct data type and when composed with `#combine` they know to expect
associated relations.  -->

## Validation

ActiveRecord mixes domain-specific data validation with persistence layer. An
active record object validates itself using its own validation rules. We feel
this ultimately ends up complicating persistence logic especially when tuning
queries in larger projects as the single source of validation needs to work in
every context the model is used.

ROM on the other hand does not have a validation concept built-in. Validations
in ROM projects need to be handled externally by separate libraries and
validated data can be passed down to the command layer to be persisted. We
expect users to validate data at the system boundaries using rules that
make sense in the current context.


## Where ROM Shines

### Database Support

As long as there is an adapter, ROM can theoretically support any datastore.

```ruby
class Users < ROM::Relation[:mongo]
  schema do
    attribute :_id, Types::ObjectID
    attribute :name, Types::String
  end
end
```

### Cross Database Associations

Couple multi-database support with cross database associations and suddenly
a world of opportunity opens up.

```ruby
class Users < ROM::Relation[:sql]
  schema(infer: true) do
    associations do
      has_many :tasks, override: true, view: :for_users
    end
  end
end

class Tasks < ROM::Relation[:yaml]
  gateway :external
  
  schema(infer: true)
  
  def for_users(_assoc, users)
    tasks.restrict(UserId: users.pluck(:id))
  end
end
```

### Mapping Custom Models

```ruby
class CustomUser < MySuperModelLibary
end

users_relation.map_to(CustomUser).first

#> #<CustomUser id="1", username="Joe">
```

ROM does not care what your final output object is as long as it accepts a hash
of all the attributes and their values. Coupled with other mappers, the output
from a query can be incredibly flexible.

### SQL Functions

<h4 class="text-center">Active Record</h4>
```ruby
User
  .select("*, concat(first_name, ' ', last_name) as 'full_name')")
  .first

#> #<User id=1 full_name="Jane Doe">
```


<h4 class="text-center">ROM</h4>
```ruby
users_relation.select_append {
  str::first_name.concat(' ', last_name).as(:full_name)
}.first

#> #<ROM::Struct::User id=1, full_name="Jane Doe">
```

### Legacy Schemas

<h4 class="text-center">Active Record</h4>
```ruby
class User < ApplicationRecord
  self.table_name = 'SomeHorriblyNamedUserTable'
  self.primary_key = 'UserIdentifier'

  alias_attribute :id, :UserIdentifier
  alias_attribute :name, :UserName
end

User.find_by(name: 'Jane')

#> #<User UserIdentifier: "2", UserName: "Jane">

User.where('name IS ?', 'Jane').first

# 🔥🔥 KA-BOOM! 🔥🔥
# ActiveRecord::StatementInvalid: no such column
```


<h4 class="text-center">ROM</h4>
```ruby
class Users < ROM::Relation[:sql]
  schema(:SomeHorriblyNamedUserTable, as: :users) do
    attribute :UserIdentifier, Serial.meta(alias: :id)
    attribute :UserName, String.meta(alias: :name)
  end
end

users_relation.where(name: 'Jane').first

#> #<ROM::Struct::User id=1 name="Jane">
```

ROM makes working with legacy schemas a breeze. All that's needed it to define
attributes on the relations schema along with
return types and aliases. Afterwards just reuse the aliased names throughout
your ROM queries - *quick* and *easy*.

Working with ActiveRecord in this regard is a bit more difficult. While you
can alias attributes, there is no real supported method for changing attribute
names. Worse yet, ActiveRecord breaks the rule of Least Surprise because while
some parts of the ActiveRecord API takes `alias_attribute` into account,
[arel](https://github.com/rails/arel)
does not, causing performance tuning SQL queries to fall back on the
ugly database attribute names you were trying to avoid.

### Custom Mappers

```ruby
class EncryptionMapper < ROM::Mapper
  register_as :encryption

  def call(relation)
    relation.map {|tuple|
      # do whatever you want
    }
  end
end

users.map_with(:encryption)
```

### Transform Data Before Persisting

Not only can data be transformed when reading records from the database, they
can also be transformed just before storage as well. Changesets offer a built in
method for executing a set of transformations that can be used to make minor
adjustments such as the example below, where an attribute needs to be renamed.
They can also handle more powerful transformations such as flattening nested
objects. For more information on available transformations see 
[Transproc](https://github.com/solnic/transproc)

```ruby
class NewUser < ROM::Changeset::Create
  map do
    rename_keys user_name: :name
  end
end

users_relation.changeset(NewUser, user_name: "Jane").commit
```

## NEXT

To further understand ROM it is recommended to review the 
[Core Concepts](/%{version}/learn/getting-started/core-concepts) page
followed by the guides under Core. 
