# frozen_string_literal: true

module ActiveModelPersistence
  # An Index keeps a map from a key to zero of more objects
  # @api public
  #
  class Index
    # The name of the index
    #
    # @example
    #   i = Index.new(name: 'id', key_source: :id, unique: true)
    #   i.name # => 'id'
    #
    # @return [String] The name of the index
    #
    attr_reader :name

    # Defines how the object's key value is calculated
    #
    # If a proc is provided, it will be called with the object as an argument to get the key value.
    #
    # If a symbol is provided, it will identify the method to call on the object to get the key value.
    #
    # @example
    #   i = Index.new(name: 'id', key_value_source: :id, unique: true)
    #   i.key_value_source # => :id
    #
    # @return [Symbol, Proc] the method name or proc used to calculate the index key
    #
    attr_reader :key_value_source

    # Determines if a key value can index more than one object
    #
    # The default value is false.
    #
    # If true, if two objects have the same key, a UniqueContraintError will be raised
    # when trying to add the second object.
    #
    # @example
    #   i = Index.new(name: 'id', key_value_source: :id, unique: true)
    #   i.unique? # => true
    #
    # @return [Boolean] true if the index is unique
    #
    attr_reader :unique

    alias unique? unique

    # Create an Index
    #
    # @example An object that can be indexed must include Indexable (which includes PrimaryKey)
    #   Employee = Struct.new(:id, :name, keyword_init: true)
    #     include ActiveModelPersistence::Indexable
    #   end
    #   e1 = Employee.new(id: 1, name: 'James')
    #   e2 = Employee.new(id: 2, name: 'Frank')
    #   e3 = Employee.new(id: 1, name: 'Margaret') # Note e1.id == e3.id
    #
    # @example
    #   i = Index.new(name: 'id', key_source: :id, unique: true)
    #   i.name # => 'id'
    #   i.key_source # => :id -- get the key value by calling the 'id' method on object
    #   i.unique # => true -- each key can only have one object associated with it
    #
    #   i.objects(e1.id) # => []
    #   i.add(e1)
    #   i.add(e2)
    #   i.objects(e1.id) # => [e1]
    #   i.objects(e2.id) # => [e2]
    #   i.add(e3) # => raises a UniqueContraintError since e1.id == e3.id
    #   i.add(e1) # => raises an ObjectAlreadyInIndexError
    #
    # @param name [String] the name of the index
    # @param key_value_source [Symbol, Proc] the attribute name or proc used to calculate the index key
    # @param unique [Boolean] when true the index will only allow one object per key
    #
    def initialize(name:, key_value_source: nil, unique: false)
      @name = name.to_s
      @key_value_source = determine_key_value_source(name, key_value_source)
      @unique = unique
      @key_to_objects_map = {}
    end

    # Returns the objects that match the key
    #
    # A unique index will return an Array containing zero or one objects. A non-unique
    # index will return an array containing zero or more objects.
    #
    # @example
    #   i = Index.new(name: 'id', key_source: :id, unique: true)
    #   e = Employee.new(id: 1, name: 'James')
    #   i.object(e.id) # => []
    #   i.add(e.id, e)
    #   i.object(e.id) # => [e]
    #
    # @param key [Object] the key to search for
    #
    # @return [Array<Object>] the objects that match the key
    #
    def objects(key)
      key_to_objects_map[key] || []
    end

    # Returns true if the index contains an object with the given key
    #
    # @example
    #   i = Index.new(name: 'id', key_source: :id, unique: true)
    #   e = Employee.new(id: 1, name: 'James')
    #   i.include?(e.id) # => false
    #   i << e
    #   i.include?(e.id) # => true
    #
    # @param key [Object] the key to search for
    #
    # @return [Boolean] true if the index contains an object with the given key
    #
    def include?(key)
      key_to_objects_map.key?(key)
    end

    # Adds an object to the index
    #
    # If the object was already in the index using a different key, remote the object
    # from the index using the previous key before adding it again.
    #
    # @example
    #   i = Index.new(name: 'id', key_source: :id, unique: true)
    #   e = Employee.new(id: 1, name: 'James')
    #   i << e
    #   i.objects(1) # => [e]
    #   e.id = 2
    #   i << e
    #   i.objects(1) # => []
    #   i.objects(2) # => [e]
    #
    # @param object [Object] the object to add to the index
    #
    # @return [Index] self so calls can be chained
    #
    # @raise [UniqueConstraintError] if the index is unique and there is already an index
    #   entry for the same key
    #
    def add_or_update(object)
      previous_key = object.previous_index_key(name)
      key = key_value_for(object)

      return if previous_key == key

      remove(object, previous_key) unless previous_key.nil?

      add(object, key) unless key.nil?

      self
    end

    alias << add_or_update

    # Removes an object from the index
    #
    # @example
    #   i = Index.new(name: 'id', key_source: :id, unique: true)
    #   e = Employee.new(id: 1, name: 'James')
    #   i << e
    #   i.objects(1) # => [e]
    #   i.remove(e)
    #   i.objects(1) # => []
    #
    # @param object [Object] the object to remove from the index
    # @param key [Object] the object's key in the index
    #   If nil (the default), call the object.previous_index_key to get the key.
    #   `previous_index_key` is implemented by the Indexable concern.
    #
    # @return [void]
    #
    # @raise [ObjectNotInIndexError] if the object is not in the index
    #
    def remove(object, key = nil)
      key ||= object.previous_index_key(name)

      raise ActiveModelPersistence::ObjectNotInIndexError if key.nil?

      remove_object_from_index(object, key)

      nil
    end

    # Removes all objects from the index
    #
    # @example
    #   i = Index.new(name: 'id', key_source: :id, unique: true)
    #   e1 = Employee.new(id: 1, name: 'James')
    #   e2 = Employee.new(id: 2, name: 'Frank')
    #   i << e1 << e2
    #   i.objects(1) # => [e1]
    #   i.objects(2) # => [e2]
    #   i.remove_all
    #   i.objects(1) # => []
    #   i.objects(2) # => []
    #
    # @return [void]
    #
    def remove_all
      @key_to_objects_map.each_pair do |_key, objects|
        objects.each do |object|
          object.clear_index_key(name)
        end
      end
      @key_to_objects_map = {}
      nil
    end

    protected

    # The map of keys to objects
    #
    # @return [Hash<Object, Array<Object>>] the map from key to an array objects added for that key
    #
    # @api private
    #
    attr_reader :key_to_objects_map

    private

    # Remove an object from the index with no additional checks
    #
    # @return [void]
    #
    # @api private
    #
    def remove_object_from_index(object, key)
      key_to_objects_map[key].delete_if { |o| o.primary_key == object.primary_key }
      key_to_objects_map.delete(key) if key_to_objects_map[key].empty?
      object.clear_index_key(name)
    end

    # Adds an object to the index
    #
    # @param object [Object] the object to add to the index
    # @param key [Object] the object's key in the index
    #
    # @return [void]
    #
    # @raise [UniqueConstraintError] if the index is unique and there is already an index
    #   entry for the same key
    #
    # @api private
    #
    def add(object, key)
      raise UniqueConstraintError if unique? && include?(key)

      key_to_objects_map[key] = [] unless key_to_objects_map.include?(key)
      key_to_objects_map[key] << object
      object.save_index_key(name, key)
    end

    # Uses the `key_value_source` to calculate the key value for the given object
    #
    # @param object [Object] the object to calculate the key value for
    #
    # @return [Object] the key value
    #
    # @api private
    #
    def key_value_for(object)
      if key_value_source.is_a?(Proc)
        key_value_source.call(object)
      else
        object.send(key_value_source)
      end
    end

    # Determine the value for key_value_source
    #
    # @return [Symbol, Proc] the value for key_value_source
    #
    # @api private
    #
    def determine_key_value_source(name, key_value_source)
      @key_value_source =
        case key_value_source
        when nil
          name.to_sym
        when Proc
          key_value_source
        else
          key_value_source.to_sym
        end
    end
  end
end
