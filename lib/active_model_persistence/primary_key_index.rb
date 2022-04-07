# frozen_string_literal: true

require 'active_model_persistence/indexable'
require 'active_model_persistence/primary_key'

module ActiveModelPersistence
  # Adds the `find` method to a model class which looks up objects by their primary key value
  #
  # @api public
  #
  module PrimaryKeyIndex
    extend ActiveSupport::Concern

    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModelPersistence::PrimaryKey
    include ActiveModelPersistence::Indexable

    # When this module is included in another class, ActiveSupport::Concern will
    # make these class methods on that class.
    #
    module ClassMethods
      # Finds an object in the :primary_key index whose primary matches the given value
      #
      # @example
      #   class Employee
      #     include ActiveModelPersistence::PrimaryKeyIndex
      #     attribute :id, :integer
      #   end
      #   e1 = Employee.new(id: 1)
      #   e1.update_indexes
      #   Employee.find(1) #=> e1
      #   Employee.find(2) #=> nil
      #
      # @param primary_key_value [Object] The primary key value to find in the :primary_key index
      #
      # @return [Object, nil] The object in the :primary_key index whose primary matches the given value
      #
      def find(primary_key_value)
        find_by_primary_key(primary_key_value).first
      end

      # Create the primary key index
      #
      # @return [void]
      #
      # @api private
      #
      def self.extended(base)
        base.index('primary_key', key_value_source: :primary_key, unique: true)
      end
    end

    included do
      # Returns the primary key index
      #
      # @return [ActiveModelPersistence::Index]
      #
      # @api private
      #
      def primary_key_index
        self.class.indexes[:primary_key]
      end
    end
  end
end
