# frozen_string_literal: true

require 'active_support'
require 'active_model'

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
  class ObjectNotValidError < ModelError; end

  # Raised when trying to save! or update! an object that has already been destroyed
  class ObjectDestroyedError < ModelError; end
end

require_relative 'active_model_persistence/index'
require_relative 'active_model_persistence/indexable'
require_relative 'active_model_persistence/persistence'
require_relative 'active_model_persistence/primary_key'
require_relative 'active_model_persistence/primary_key_index'
require_relative 'active_model_persistence/version'
