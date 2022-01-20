# frozen_string_literal: true

require 'active_model_persistence/indexable'
require 'active_model_persistence/primary_key'
require 'active_model_persistence/primary_key_index'

module ActiveModelPersistence
  # This mixin adds the ability to store and manage Ruby objects in an in-memory object store.
  # These objects are commonly called 'models'.
  #
  # @example
  #   class ModelExample
  #     include ActiveModelPersistence::Persistence
  #     attribute :id, :integer
  #     attribute :name, :string
  #     index :id, unique: true
  #     validates :id, presence: true
  #   end
  #
  #   # Creating a model instance with `.new` does not save it to the object store
  #   #
  #   m = ModelExample.new(id: 1, name: 'James')
  #   m.new_record? # => true
  #   m.persisted? # => false
  #   m.destroyed? # => false
  #
  #   # `save` will save the object to the object store
  #   #
  #   m.save
  #   m.new_record? # => false
  #   m.persisted? # => true
  #   m.destroyed? # => false
  #
  #   # Once an object is persisted, it can be fetched from the object store using `.find`
  #   # and `.find_by_*` methods.
  #   m2 = ModelExample.find(1)
  #   m == m2 # => true
  #
  #   m2 = ModelExample.find_by_id(1)
  #   m == m2 # => true
  #
  #   # `destroy` will remove the object from the object store
  #   #
  #   m.destroy
  #   m.new_record? # => true
  #   m.persisted? # => false
  #   m.destroyed? # => true
  #
  module Persistence
    extend ActiveSupport::Concern

    include ActiveModelPersistence::Indexable
    include ActiveModelPersistence::PrimaryKey
    include ActiveModelPersistence::PrimaryKeyIndex

    # When this module is included in another class, ActiveSupport::Concern will
    # make these class methods on that class.
    #
    module ClassMethods
      # Creates a new model object in to the object store and returns it
      #
      # Create a new model object passing `attributes` and `block` to `.new` and then calls `#save`.
      #
      # The new model object is returned even if it could not be saved to the object store.
      #
      # @param attributes [Hash, Array<Hash>] attributes
      #
      #   The attributes to set on the model object. These are passed to the model's `.new` method.
      #
      #   Multiple model objects can be created by passing an array of attribute Hashes.
      #
      # @param block [Proc] options
      #
      #   The block to pass to the model's `.new` method.
      #
      # @example
      #   m = ModelExample.new(id: 1, name: 'James')
      #   m.id #=> 1
      #   m.name #=> 'James'
      #
      # @example Multiple model objects can be created
      #   array_of_attributes = [
      #     { id: 1, name: 'James' },
      #     { id: 2, name: 'Frank' }
      #   ]
      #   objects = ModelExample.create(array_of_attributes)
      #   objects.class #=> Array
      #   objects.size #=> 2
      #   objects.first.id #=> 1
      #   objects.map(&:name) #=> ['James', 'Frank']
      #
      # @return [Object, Array<Object>] the model object or array of model objects created
      #
      def create(attributes = nil, &block)
        if attributes.is_a?(Array)
          attributes.collect { |attr| create(attr, &block) }
        else
          new(attributes, &block).tap(&:save)
        end
      end

      # Creates a new model object in to the object store
      #
      # Raises an error if the object could not be created.
      #
      # Create a new model object passing `attributes` and `block` to `.new` and then calls `#save!`.
      #
      # @param attributes [Hash, Array<Hash>] attributes
      #
      #   The attributes to set on the model object. These are passed to the model's `.new` method.
      #
      #   Multiple model objects can be created by passing an array of attribute Hashes.
      #
      # @param block [Proc] options
      #
      #   The block to pass to the model's `.new` method.
      #
      # @example
      #   m = ModelExample.new(id: 1, name: 'James')
      #   m.id #=> 1
      #   m.name #=> 'James'
      #
      # @example Multiple model objects can be created
      #   array_of_attributes = [
      #     { id: 1, name: 'James' },
      #     { id: 2, name: 'Frank' }
      #   ]
      #   objects = ModelExample.create(array_of_attributes)
      #   objects.class #=> Array
      #   objects.size #=> 2
      #   objects.first.id #=> 1
      #   objects.map(&:name) #=> ['James', 'Frank']
      #
      # @return [Object, Array<Object>] the model object or array of model objects created
      #
      # @raise [ModelError] if the model object could not be created
      #
      def create!(attributes = nil, &block)
        if attributes.is_a?(Array)
          attributes.collect { |attr| create!(attr, &block) }
        else
          new(attributes, &block).tap(&:save!)
        end
      end

      # Return all model objects that have been saved to the object store
      #
      # @example
      #   array_of_attributes = [
      #     { id: 1, name: 'James' },
      #     { id: 2, name: 'Frank' }
      #   ]
      #   ModelExample.create(array_of_attributes)
      #   ModelExample.all.count #=> 2
      #   ModelExample.all.map(&:id) #=> [1, 2]
      #   ModelExample.all.map(&:name) #=> ['James', 'Frank']
      #
      # @return [Array<Object>] the model objects in the object store
      #
      def all
        object_array.each
      end

      # The number of model objects saved in the object store
      #
      # @example
      #   array_of_attributes = [
      #     { id: 1, name: 'James' },
      #     { id: 2, name: 'Frank' }
      #   ]
      #   ModelExample.create(array_of_attributes)
      #   ModelExample.all.count #=> 2
      #
      # @return [Integer] the number of model objects in the object store
      #
      def count
        object_array.size
      end

      alias size count

      # Removes all model objects from the object store
      #
      # Each saved model object's `#destroy` method is called.
      #
      # @example
      #   array_of_attributes = [
      #     { id: 1, name: 'James' },
      #     { id: 2, name: 'Frank' }
      #   ]
      #   ModelExample.create(array_of_attributes)
      #   ModelExample.all.count #=> 2
      #   ModelExample.destroy_all
      #   ModelExample.all.count #=> 0
      #
      # @return [void]
      #
      def destroy_all
        object_array.first.destroy while object_array.size.positive?
      end

      # Removes all model objects from the object store
      #
      # Each saved model object's `#destroy` method is NOT called.
      #
      # @example
      #   array_of_attributes = [
      #     { id: 1, name: 'James' },
      #     { id: 2, name: 'Frank' }
      #   ]
      #   ModelExample.create(array_of_attributes)
      #   ModelExample.all.count #=> 2
      #   ModelExample.destroy_all
      #   ModelExample.all.count #=> 0
      #
      # @return [void]
      #
      def delete_all
        @object_array = []
        indexes.values.each(&:remove_all)
        nil
      end

      # private

      # All saved model objects are stored in this array (this is the object store)
      #
      # @return [Array<Object>] the model objects in the object store
      #
      # @api private
      #
      def object_array
        @object_array ||= []
      end
    end

    # rubocop:disable Metrics/BlockLength
    included do
      # Returns true if this object hasn't been saved or destroyed yet
      #
      # @example
      #   object = ModelExample.new(id: 1, name: 'James')
      #   object.new_record? #=> true
      #   object.save
      #   object.new_record? #=> false
      #   object.destroy
      #   object.new_record? #=> false
      #
      # @return [Boolean] true if this object hasn't been saved yet
      #
      def new_record?
        if instance_variable_defined?(:@new_record)
          @new_record
        else
          @new_record = true
        end
      end

      # Returns true if this object has been destroyed
      #
      # @example Destroying a saved model object
      #   object = ModelExample.new(id: 1, name: 'James')
      #   object.destroyed? #=> false
      #   object.save
      #   object.destroyed? #=> false
      #   object.destroy
      #   object.destroyed? #=> true
      #
      # @example Destroying a unsaved model object
      #   object = ModelExample.new(id: 1, name: 'James')
      #   object.destroyed? #=> false
      #   object.destroy
      #   object.destroyed? #=> true
      #
      # @return [Boolean] true if this object has been destroyed
      #
      def destroyed?
        if instance_variable_defined?(:@destroyed)
          @destroyed
        else
          @destroyed = false
        end
      end

      # Returns true if the record is persisted in the object store
      #
      # @example
      #   object = ModelExample.new(id: 1, name: 'James')
      #   object.persisted? #=> false
      #   object.save
      #   object.persisted? #=> true
      #   object.destroy
      #   object.persisted? #=> false
      #
      # @return [Boolean] true if the record is persisted in the object store
      #
      def persisted?
        !(new_record? || destroyed?)
      end

      # Saves the model object in the object store and updates all indexes
      #
      # @example
      #   ModelExample.all.count #=> 0
      #   object = ModelExample.new(id: 1, name: 'James')
      #   ModelExample.all.count #=> 0
      #   object.save
      #   ModelExample.all.count #=> 1
      #
      # @param options [Hash] save options (currently unused)
      # @param block [Proc] a block to call after the save
      #
      # @yield [self] a block to call after the save
      # @yieldparam saved_model [self] the model object after it was saved
      # @yieldreturn [void]
      #
      # @return [Boolean] true if the model object was saved
      #
      def save(**options, &block)
        save!(**options, &block)
      rescue ModelError
        false
      else
        true
      end

      # Calls #save and raises an error if #save returns false
      #
      # @example
      #   object = ModelExample.new(id: nil, name: 'James')
      #   object.save! #=> raises ObjectNotSavedError
      #
      # @param _options [Hash] save options (currently unused)
      #
      # @param block [Proc] a block to call after the save
      #
      # @yield [self] a block to call after the save
      # @yieldparam saved_model [self] the model object after it was saved
      # @yieldreturn [void]
      #
      # @raise [ObjectNotSavedError] if the model object was not saved
      #
      # @return [Boolean] returns true or raises an error
      #
      def save!(**_options, &block)
        raise ObjectDestroyedError if destroyed?
        raise ObjectNotValidError unless valid?

        new_record? ? _create(&block) : _update(&block)
        update_indexes
        true
      end

      # Deletes the object from the object store
      #
      # This model object is frozen to reflect that no changes should be made
      # since they can't be persisted.
      #
      # @example
      #   ModelExample.create(id: 1, name: 'James')
      #   object = ModelExample.create(id: 2, name: 'Frank')
      #   object.destroyed? #=> false
      #   ModelExample.all.count #=> 2
      #   object.destroy
      #   object.destroyed? #=> true
      #   ModelExample.all.count #=> 1
      #   ModelExample.all.first.name #=> 'James'
      #
      # @return [void]
      #
      def destroy
        if persisted?
          remove_from_indexes
          self.class.object_array.delete_if { |o| o.primary_key == primary_key }
        end
        @new_record = false
        @destroyed = true
        freeze
      end

      def ==(other)
        attributes == other.attributes
      end

      # Updates the attributes of the model and saves it
      #
      # The attributes are updated from the passed in hash. If the object is invalid,
      # the save will fail and false will be returned.
      #
      # @example
      #   object = ModelExample.create(id: 1, name: 'James')
      #   object.update(name: 'Frank')
      #   object.find(1).name #=> 'Frank'
      #
      # @param attributes [Hash] the attributes to update
      #
      # @return [Boolean] true if the model object was saved, otherwise false
      #
      def update(attributes)
        update!(attributes)
      rescue ModelError
        false
      else
        true
      end

      # Updates just like #update but an exception is raised of the model is invalid
      #
      # @example
      #   object = ModelExample.create(id: 1, name: 'James')
      #   object.update!(id: nil) #=> raises ObjectNotSavedError
      #
      # @param attributes [Hash] the attributes to update
      #
      # @return [Boolean] true if the model object was saved, otherwise an error is raised
      #
      # @raise [ObjectNotValidError] if the model object is invalid
      # @raise [ObjectDestroyedError] if the model object was previously destroyed
      #
      def update!(attributes)
        raise ObjectDestroyedError if destroyed?

        assign_attributes(attributes)
        save!
      end

      private

      # Creates a record with values matching those of the instance attributes
      # and returns its id.
      #
      # @return [Object] the primary_key of the created object
      #
      # @api private
      #
      def _create
        return false unless primary_key?
        raise UniqueContraintError if primary_key_index.include?(primary_key)

        self.class.object_array << self

        @new_record = false

        yield(self) if block_given?

        primary_key
      end

      # Updates an object that is already in the object store
      #
      # @return [Boolean] true if the object was update successfully, otherwise raises a ModelError
      #
      # @api private
      #
      def _update
        raise RecordNotFound unless primary_key_index.include?(primary_key)

        yield(self) if block_given?

        true
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
