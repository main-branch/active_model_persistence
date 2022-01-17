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
