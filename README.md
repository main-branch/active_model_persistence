# active_model_persistence

[![Gem Version](https://badge.fury.io/rb/active_model_persistence.svg)](https://badge.fury.io/rb/active_model_persistence)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/Documentation-OK-green.svg)](https://jcouball.github.io/github_pages_rake_tasks/)

A gem to add in-memory persistence to Models built with ActiveModel.

The goals of this gem are:

* Add ActiveRecord-like meta-programming to configure Models used for ETI (Extract,
  Transform, Load) work where a lot of data is loaded from desparate sources, transformed
  in memory, and then written to other sources.
* Make creation of these model objects consistent across several different teams,
* Make it so easy to create model objects that teams will use these models instead
  of using hashs
* Encourage a separation from the models from the business logic of reading, transforming,
  and writing the data
* Make it easy to use FactoryBot to generate test data instead of having to maintain a
  bunch of fixture files.

An example model built with this gem might look like this:

```ruby
require 'active_model_persistence'

class Employee
  include ActiveModelPersistence::Persistence

  # Use ActiveModel attributes and validations to define the model's state

  attribute :id, :string
  attribute :name, :string
  attribute :manager_id, :string

  validates :id, presence: true
  validates :name, presence: true

  # A unique index is automatically created on the primary key attribute (which is :id by default)
  # index :id, unique: true

  # You can set the primary key attribute if you are using a different attribute for
  # the primary key using the statement `self.primary_key = attribute_name`

  # Indexes are non-unique by default and create a `find_by_{index_name}` method on
  # the model class.
  index :manager_id
end
```

Use the employee model like you would an ActiveRecord model:

```ruby
e1 = Enmployee.create(id: 'jdoe1', name: 'John Doe', manager_id: 'boss')
e2 = Enmployee.create(id: 'jdoe2', name: 'Bob Doe', manager_id: 'boss')
e3 = Enmployee.create(id: 'boss', name: 'Boss Person')

# The `find` method looks up objects by the primary key and returns a single object or nil
Employee.find('jdoe1') #=> [e1]

# The `find_by_*` methods return a (possibly empty) object array based on the indexes
# declared in the model class.
Employee.find_by_manager_id('boss') #=> [e1, e2]

# etc.
```

## Inheritance

ActiveModelPersistence supports inheritance in models. Include
`ActiveModelPersistence::Persistence` only in the base class.

Here is an example with a `User` base class and two derived clases `Employee` and `Member`.
Each derived class adds different attributes and indexes.

```ruby
require 'active_model_persistence'

class User
  include ActiveModelPersistence::Persistence

  attribute :id, :integer
  attribute :name, :string
end

class Employee < User
  attribute :manager_id, :integer

  index :manager_id, unique: false
end

class Member < User
  attribute :joined_on, :date, default: Date.today

  index :joined_on, unique: false
end
```

As an example, say we have one instance of each class:

```ruby
user = User.create!(id: 1, name: 'User James')
employee = Employee.create!(id: 2, name: 'Employee Bob', manager_id: nil)
member = Member.create!(id: 3, name: 'Member Mary', joined_on: Date.parse('2022-01-01'))
```

The primary key is shared by all objects of these classes so it must be unique for
all objects created from these classes. For instance:

```ruby
require 'rspec-expectations'
include RSpec::Matchers

# Creating a Member with the same primary key as a User will fail
expect { Member.create!(id: 1, name: 'Member Jason') }.to(
  raise_error(ActiveModelPersistence::UniqueConstraintError)
)
```

Calling a find method such as `find` or `find_by_*` on a class will only return
objects that are a kind of that class.

That means calling a find method on `User` will return users, employees, or members:

```ruby
expect(User.find(1)).to eq(user)
expect(User.find(2)).to eq(employee)
expect(User.find(3)).to eq(member)
```

While calling a find method on `Employee` will only return employees:

```ruby
expect(Employee.find(1)).to be_nil
expect(Employee.find(2)).to eq(employee)
expect(Employee.find(3)).to be_nil
```

`all`, `count`, `delete_all`, `destroy_all` and other methods similarly limit what
objects are acted upon based on what class they are called on.

## API Documentation

See [the full API documentation](https://jcouball.github.io/active_record_persistence/) for more details.

## Installation

Add this line to your application's Gemfile (or equivalent comamnd in the project's gemspec):

```ruby
gem 'active_model_persistence'
```

And then execute:

```shell
bundle install
```

Or install it manually using the `gem` command:

```shell
gem install active_model_persistence
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_model_persistence.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
