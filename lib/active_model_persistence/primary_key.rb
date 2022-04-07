# frozen_string_literal: true

module ActiveModelPersistence
  # Exposes the `primary_key` accessor to read or write the primary key attribute value
  #
  # The primary key should be a unique (within its model class) identifier
  # for a model.
  #
  # By default, the `primary_key` accessors maps to the `id` attribute. You can change
  # the attribute by setting the `primary_key` at the class level.
  #
  # @example By default, the primary key maps to the `id` attribute
  #   class Employee
  #     include ActiveModelPersistence::PrimaryKey
  #     attribute :id, :integer
  #   end
  #   e1 = Employee.new(id: 1)
  #   e1.primary_key #=> 1
  #
  # @example Changing the primary key attribute
  #   class Employee
  #     include ActiveModelPersistence::PrimaryKey
  #     attribute :short_id, :string
  #     # change the primary key
  #     self.primary_key = :short_id
  #   end
  #   e1 = Employee.new(short_id: 'couballj')
  #   # `primary_key` can be used as an alias for `short_id`
  #   e1.primary_key #=> 'couballj'
  #   e1.primary_key = 'fthrock'
  #   e1.short_id #=> 'fthrock'
  #
  # @api public
  #
  module PrimaryKey
    extend ActiveSupport::Concern

    include ActiveModel::Model
    include ActiveModel::Attributes

    # When this module is included in another class, ActiveSupport::Concern will
    # make these class methods on that class.
    #
    module ClassMethods
      # Identifies the attribute that the `primary_key` accessor maps to
      #
      # The primary key is 'id' by default.
      #
      # @example
      #   class Employee
      #     include ActiveModelPersistence::PrimaryKey
      #     attribute :username, :string
      #     self.primary_key = :username
      #   end
      #   Employee.primary_key #=> :username
      #
      # @return [Symbol] the attribute that the `primary_key` accessor is an alias for
      #
      def primary_key
        @primary_key ||= 'id'
      end

      # Sets the attribute to use for the primary key
      #
      # @example
      #   class Employee
      #     include ActiveModelPersistence::PrimaryKey
      #     attribute :username, :string
      #     primary_key = :username
      #   end
      #   e = Employee.new(username: 'couballj')
      #   e.primary_key #=> 'couballj'
      #
      # @param attribute [Symbol] the attribute to use for the primary key
      #
      # @return [void]
      #
      def primary_key=(attribute)
        @primary_key = attribute.to_s
      end
    end

    included do
      # Returns the primary key attribute's value
      #
      # @example
      #   class Employee
      #     include ActiveModelPersistence::PrimaryKey
      #     attribute :username, :string
      #     self.primary_key = :username
      #   end
      #   e = Employee.new(username: 'couballj')
      #   e.primary_key #=> 'couballj'
      #
      # @return [Object] the primary key attribute's value
      #
      def primary_key
        __send__(self.class.primary_key)
      end

      # Sets the primary key atribute's value
      #
      # @example
      #   class Employee
      #     include ActiveModelPersistence::PrimaryKey
      #     attribute :username, :string
      #     primary_key = :username
      #   end
      #   e = Employee.new(username: 'couballj')
      #   e.primary_key = 'other'
      #   e.username #=> 'other'
      #
      # @param value [Object] the value to set the primary key attribute to
      #
      # @return [void]
      #
      def primary_key=(value)
        __send__("#{self.class.primary_key}=", value)
      end

      # Returns true if the primary key attribute's value is not null or empty
      #
      # @example
      #   class Employee
      #     include ActiveModelPersistence::PrimaryKey
      #     attribute :id, :integer
      #   end
      #   e = Employee.new
      #   e.primary_key #=> nil
      #   e.primary_key? #=> false
      #   e.primary_key = 1
      #   e.primary_key? #=> true
      #
      # @return [Boolean] true if the primary key attribute's value is not null or empty
      #
      def primary_key?
        primary_key.present?
      end
    end
  end
end
