# frozen_string_literal: true

require 'active_model_persistence/index'
require 'active_model_persistence/primary_key'

module ActiveModelPersistence
  # Include in your model to enable index support
  #
  # Define an index in the model's class using the `index` method. This will create a `find_by_*`
  # method for each index to find the objects by their keys.
  #
  # Each index has a name which must be unique for the model. The name is used to create the
  # `find_by_*` method. eg. for the 'id' index, the `find_by_id` method will be created.
  #
  # Unique indexes are defined by passing `unique: true` to the `index` method. A unique index
  # defines a `find_by_*` method that will return a single object or nil if no object is found for
  # the key.
  #
  # A non-unique index will define a `find_by_*` method that will return an array of objects which
  # may be empty.
  #
  # @example
  #   class Employee
  #     include ActiveModelPersistence::Indexable
  #
  #     # Define ActiveModel attributes
  #     attribute :id, :integer
  #     attribute :name, :string
  #     attribute :manager_id, :integer
  #     attribute :birth_date, :date
  #
  #     # Define indexes
  #     index :id, unique: true
  #     index :manager_id, key_value_source: :manager_id
  #     index :birth_year, key_value_source: ->(o) { o.birth_date.year }
  #   end
  #
  #   e1 = Employee.new(id: 1, name: 'James', manager_id: 3, birth_date: Date.new(1967, 3, 15))
  #   e2 = Employee.new(id: 2, name: 'Frank', manager_id: 3, birth_date: Date.new(1968, 1, 27))
  #   e3 = Employee.new(id: 3, name: 'Aaron', birth_date: Date.new(1968, 6, 16))
  #
  #   # This should be done by Employee.create or Employee#save from ActiveModelPersistence::Persistence
  #   [e1, e2, e3].each { |e| e.update_indexes }
  #
  #   # Use the find_by_* methods to find objects
  #   #
  #   Employee.find_by_id(1).name # => 'James'
  #   Employee.find_by_manager_id(3).map(&:name) # => ['James', 'Frank']
  #   Employee.find_by_birth_year(1967).map(&:name) # => ['James']
  #   Employee.find_by_birth_year(1968).map(&:name) # => ['Frank', 'Aaron']
  #
  module Indexable
    extend ActiveSupport::Concern

    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModelPersistence::PrimaryKey

    # When this module is included in another class, ActiveSupport::Concern will
    # make these class methods on that class.
    #
    module ClassMethods
      # Returns a hash of indexes for the model keyed by name
      #
      # @example
      #   Employee.indexes.keys # => %w[id manager_id birth_year]
      #
      # @return [Hash<String, ActiveModelPersistence::Index>] the indexes defined by the model
      #
      def indexes
        @indexes ||= {}
      end

      # Adds an index to the model
      #
      # @example Add a unique index on the id attribute
      #   Employee.index(:id, unique: true)
      #
      # @example with a key_value_source when the name and the attribute are different
      #   Employee.index(:manager, key_value_source: :manager_id)
      #
      # @example with a Proc for key_value_source
      #   Employee.index(:birth_year, key_value_source: ->(o) { o.birth_date.year })
      #
      # @param index_name [String] the name of the index
      # @param options [Hash] the options for the index
      # @option options :unique [Boolean] whether the index is unique, default is false
      # @option options :key_value_source [Symbol, Proc] the source of the key value of the object for this index
      #
      #   If a Symbol is given, it will name a zero arg method on the object which returns
      #   the key's value. If a Proc is given, the key's value will be the result of calling the
      #   Proc with the object.
      #
      # @return [void]
      #
      def index(index_name, **options)
        index = Index.new(**default_index_options(index_name).merge(options))
        indexes[index_name.to_sym] = index

        singleton_class.define_method("find_by_#{index_name}") do |key|
          index.objects(key).tap do |objects|
            objects.each { |o| o.instance_variable_set(:@previously_new_record, false) }
          end
        end
      end

      # Adds or updates all defined indexes for the given object
      #
      # Call this after changing the object to ensure the indexes are up to date.
      #
      # @example
      #   e1 = Employee.new(id: 1, name: 'James', manager_id: 3, birth_date: Date.new(1967, 3, 15))
      #   Employee.update_indexes(e1)
      #   Employee.find_by_id(1) # => e1
      #   Employee.find_by_manager_id(3) # => [e1]
      #   Employee.find_by_birth_year(1967) # => [e1]
      #
      #   e1.birth_date = Date.new(1968, 1, 27)
      #   Employee.find_by_birth_year(1968) # => []
      #   Employee.update_indexes(e1)
      #   Employee.find_by_birth_year(1968) # => [e1]
      #
      # @param object [Object] the object to add to the indexes
      #
      # @return [void]
      #
      def update_indexes(object)
        indexes.each_value { |index| index.add_or_update(object) }
      end

      # Removes the given object from all defined indexes
      #
      # Call this before deleting the object to ensure the indexes are up to date.
      #
      # @example
      #   e1 = Employee.new(id: 1, name: 'James', manager_id: 3, birth_date: Date.new(1967, 3, 15))
      #   Employee.update_indexes(e1)
      #   Employee.find_by_id(1) # => e1
      #   Employee.remove_from_indexes(e1)
      #   Employee.find_by_id(1) # => nil
      #
      # @param object [Object] the object to remove from the indexes
      #
      # @return [void]
      #
      def remove_from_indexes(object)
        indexes.each_value { |index| index.remove(object) }
      end

      private

      # Defines the default options for a new ActiveModelPersistence::Index
      #
      # @return [Hash] the default options
      #
      # @api private
      #
      def default_index_options(index_name)
        {
          name: index_name.to_sym,
          unique: false
        }
      end
    end

    included do
      # Adds the object to the indexes defined by the model
      #
      # @example
      #   e1 = Employee.new(id: 1, name: 'James', manager_id: 3, birth_date: Date.new(1967, 3, 15))
      #   e1.add_to_indexes
      #   Employee.find_by_id(1) # => e1
      #
      # @return [void]
      #
      def update_indexes
        self.class.update_indexes(self)
      end

      # Removes the object from the indexes defined by the model
      #
      # @example
      #   e1 = Employee.new(id: 1, name: 'James', manager_id: 3, birth_date: Date.new(1967, 3, 15))
      #   e1.add_to_indexes
      #   Employee.find_by_id(1) # => e1
      #   e1.remove_from_indexes
      #   Employee.find_by_id(1) # => nil
      #
      # @return [void]
      #
      def remove_from_indexes
        self.class.remove_from_indexes(self)
      end

      # Returns the key value for the object in the index named by index_name
      # @api private
      def previous_index_key(index_name)
        instance_variable_get("@#{index_name}_index_key")
      end

      # Set the key value for the object in the index named by index_name
      # @api private
      def save_index_key(index_name, key)
        instance_variable_set("@#{index_name}_index_key", key)
      end

      # Clears the key value for the object in the index named by index_name
      # @api private
      def clear_index_key(index_name)
        instance_variable_set("@#{index_name}_index_key", nil)
      end
    end
  end
end
