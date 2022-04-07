# frozen_string_literal: true

RSpec.describe ActiveModelPersistence::Index do
  describe '#initialize' do
    let(:index) { described_class.new(name: 'id', key_value_source: :id, unique: true) }
    subject { index }
    it { is_expected.to have_attributes(name: 'id', key_value_source: :id, unique: true) }
    context 'when the unique flag is not given' do
      let(:index) { described_class.new(name: 'id', key_value_source: :id) }
      it 'should set the unique flag to false' do
        is_expected.to have_attributes(unique: false)
      end
    end
    context 'when the key_value_source is not given' do
      let(:index) { described_class.new(name: 'id') }

      it 'should set the key_value_source to name.sym' do
        is_expected.to have_attributes(name: 'id', key_value_source: :id)
      end
    end
  end

  let(:indexable_class) do
    Class.new do
      include ActiveModelPersistence::Indexable

      attribute :id, :integer
      attribute :name, :string
      attribute :manager_id, :integer, default: nil
    end
  end

  let(:object1) { indexable_class.new(id: 1, name: 'James', manager_id: 3) }
  let(:object2) { indexable_class.new(id: 2, name: 'Frank', manager_id: 3) }
  let(:object3) { indexable_class.new(id: 3, name: 'Aaron') }
  let(:object4) { indexable_class.new(id: 1, name: 'Duplicate Id') }

  describe '#objects'

  describe '#include?'

  describe '#add_or_update' do
    context 'for an index whose key_value_source is a proc' do
      let(:index) { described_class.new(name: 'id', key_value_source: ->(object) { object.id * 100 }, unique: true) }

      context 'when the object is added to the index' do
        before do
          index.add_or_update(object1)
        end

        it 'should use the proc to calculate the key' do
          expect(index.objects(100)).to eq([object1])
        end
      end
    end

    context 'for a unique index' do
      let(:index) { described_class.new(name: 'id', key_value_source: :id, unique: true) }

      context 'for an object whose key is not in the index' do
        it 'should add the object to the index with the correct key' do
          expect(index.objects(1)).to be_empty
          index.add_or_update(object1)
          expect(index.objects(1)).to eq([object1])
        end
        it 'should save the index key in the object added to the index' do
          expect(object1.instance_variable_get(:@id_index_key)).to be_nil
          index.add_or_update(object1)
          expect(object1.instance_variable_get(:@id_index_key)).to eq(1)
        end
      end

      context 'when two different objects with the same key are added' do
        it 'should raise a UniqueConstraintError' do
          index.add_or_update(object1)
          expect { index.add_or_update(object4) }.to raise_error ActiveModelPersistence::UniqueConstraintError
        end
      end

      context 'when the same object is added twice' do
        it 'the second time added should not raise an error' do
          index.add_or_update(object1)
          expect { index.add_or_update(object1) }.not_to raise_error
        end
        it 'the object should only be in the index once' do
          index.add_or_update(object1)
          index.add_or_update(object1)
          expect(index.objects(1)).to eq([object1])
        end
      end

      context 'when two objects are in the index' do
        before do
          index.add_or_update(object1)
          index.add_or_update(object2)
        end
        context 'and then the second object\'s key is set to the first object\'s key' do
          before do
            object2.id = object1.id
          end
          it 'should raise a UniqueConstraintError when the index is updated for the second object' do
            expect { index.add_or_update(object2) }.to raise_error ActiveModelPersistence::UniqueConstraintError
          end
        end
      end
    end

    context 'for a non-unique index' do
      let(:index) { described_class.new(name: 'manager_id', key_value_source: :manager_id, unique: false) }

      context 'for an object whose key is not in the index' do
        it 'should add the object to the index with the correct key' do
          expect(index.objects(3)).to be_empty
          index.add_or_update(object1)
          expect(index.objects(3)).to eq([object1])
        end

        it 'should save the index key in the object added to the index' do
          expect(object1.instance_variable_get(:@manager_id_index_key)).to be_nil
          index.add_or_update(object1)
          expect(object1.instance_variable_get(:@manager_id_index_key)).to eq(3)
        end
      end

      context 'when two different objects with the same key are added' do
        it 'should add both objects to the index' do
          index.add_or_update(object1)
          expect { index.add_or_update(object2) }.not_to raise_error
          expect(index.objects(3)).to eq([object1, object2])
        end
      end

      context 'when an object is added to the index and then it\'s key is changed' do
        it 'should remove the original key from the index and add the new key' do
          index.add_or_update(object1)
          expect(index.objects(3)).to eq([object1])

          object1.manager_id = 2
          index.add_or_update(object1)
          expect(index.objects(3)).to be_empty
          expect(index.objects(2)).to eq([object1])
        end
      end
    end
  end

  describe '#remove' do
    let(:index) { described_class.new(name: 'manager_id') }

    context 'when trying to remove an object that is not in the index' do
      context 'and whose key is not in the index' do
        it 'should raise an ObjectNotInIndexError' do
          expect { index.remove(object1) }.to raise_error ActiveModelPersistence::ObjectNotInIndexError
        end
      end

      context 'and whose key is in the index (because two objects have the same key)' do
        before do
          index.add_or_update(object1)
        end

        it 'should raise an ObjectNotInIndexError' do
          expect { index.remove(object2) }.to raise_error ActiveModelPersistence::ObjectNotInIndexError
        end
      end
    end

    context 'when there is an object in the index' do
      before do
        index.add_or_update(object1)
      end
      it 'should remove the object from the index' do
        index.remove(object1)
        expect(index.objects(3)).to be_empty
      end
      it 'should remove the index key from the object' do
        index.remove(object1)
        expect(object1.instance_variable_get(:@manager_id_index_key)).to be_nil
      end
    end

    context 'when there are two objects in the index with the same key' do
      before do
        index.add_or_update(object1)
        index.add_or_update(object2)
      end
      it 'should remove the right object from the index' do
        index.remove(object1)
        expect(index.objects(3)).to eq([object2])
      end
    end
  end

  describe '#remove_all' do
    let(:index) { described_class.new(name: 'id', unique: true) }
    context 'when the index is already empty' do
      it 'should not raise an error' do
        expect { index.remove_all }.not_to raise_error
      end
    end
    context 'when there are objects in the index' do
      before do
        index.add_or_update(object1)
        index.add_or_update(object2)
        index.add_or_update(object3)
      end
      it 'should remove all objects from the index' do
        index.remove_all
        expect(index.objects(1)).to be_empty
        expect(index.objects(2)).to be_empty
        expect(index.objects(3)).to be_empty
      end
      it 'should remove the index key from the objects that were in the index' do
        index.remove_all
        expect(object1.instance_variable_get(:@manager_id_index_key)).to be_nil
        expect(object2.instance_variable_get(:@manager_id_index_key)).to be_nil
        expect(object3.instance_variable_get(:@manager_id_index_key)).to be_nil
      end
    end
  end
end

#   let(:key1) { double('key1') }
#   let(:key2) { double('key2') }
#   let(:object1) { double('object1') }
#   let(:object2) { double('object2') }

#   describe '#add_or_update' do
#     subject { index }

#     context 'for a non-unique index' do
#       let(:index_unique) { false }
#       context 'when adding two entries with the same key' do
#         it 'should succeed' do
#           expect(object1).to receive(:save_index_key).with(index_name, key1)
#           expect(object2).to receive(:save_index_key).with(index_name, key1)
#           expect { subject.add_or_update(key1, nil, object1) }.not_to raise_error
#           expect { subject.add_or_update(key1, nil, object2) }.not_to raise_error
#         end
#       end
#     end

#     context 'for a unique index' do
#       let(:index_unique) { true }
#       context 'when adding two entries with the same key' do
#         it 'should fail' do
#           # expect(object1).to receive(:save_index_key).with(index_name, key1)
#           # expect { subject.add_or_update(key1, nil, object1) }.not_to raise_error
#           # expect { subject.add_or_update(key1, nil, object2) }.to(
#           #   raise_error(ActiveModelPersistence::Errors::UniqueContraintError)
#           # )
#         end
#       end
#     end
#   end

#   describe '#remove' do
#     context 'when the key being removed is not in the index' do
#       it 'should fail' do
#         expect { index.remove(key1, object1) }.to raise_error(ActiveModelPersistence::Errors::KeyNotFoundError)
#       end
#     end

#     context 'when removing an object with a key' do
#     end
#   end

#   describe '#remove_all' do
#   end

#   describe '#target' do
#   end

#   describe '#include?' do
#   end

#   describe '#==' do
#   end
# end
