# frozen_string_literal: true

require 'active_support'
require 'active_model'

# rubocop:disable Lint/RedundantRequireStatement
require 'pp'
# rubocop:enable Lint/RedundantRequireStatement

# A set of mixins to add to ActiveModel classes to support persistence
#
# @api public
#
module ActiveModelPersistence
  # A base class for all ActiveModelPersistence errors
  class ModelError < StandardError; end

  # Raised when trying to remove a model from an index when the model is not in the index
  class ObjectNotInIndexError < ModelError; end

  # Raised when trying to add an object to an index when the key already exists in the index for another object
  class UniqueConstraintError < ModelError; end

  # Raised when trying to save an invalid object
  # @api public
  class ObjectNotValidError < ModelError
    # Create a new ObjectNotValidError constructing a message from the invalid object
    #
    # @example
    #   class Person
    #     include ActiveModelPersistence::Persistence
    #     attribute :id, :integer
    #     validates :id, presence: true
    #     attribute :name, :integer
    #     validates :name, presence: true
    #     attribute :age, :integer
    #     validates :age, numericality: { greater_than: 13, less_than: 125 }, allow_nil: true
    #   end
    #   begin
    #     Person.create!(id: 1)
    #   rescue ObjectNotValidError => e
    #     puts e.message
    #   end
    #
    # @param invalid_object [Object] the invalid object being reported
    #
    def initialize(invalid_object)
      super(error_message(invalid_object))
    end

    private

    # Create the exception message
    # @return [String] the exception message
    # @api private
    def error_message(invalid_object)
      <<~ERROR_MESSAGE
        #{invalid_object.class} object is not valid

        Errors:
        #{invalid_object.errors.full_messages.pretty_inspect}
        Attributes:
        #{invalid_object.attributes.pretty_inspect}
      ERROR_MESSAGE
    end
  end

  # Raised when trying to save! or update! an object that has already been destroyed
  class ObjectDestroyedError < ModelError; end
end

require_relative 'active_model_persistence/index'
require_relative 'active_model_persistence/indexable'
require_relative 'active_model_persistence/persistence'
require_relative 'active_model_persistence/primary_key'
require_relative 'active_model_persistence/primary_key_index'
require_relative 'active_model_persistence/version'
