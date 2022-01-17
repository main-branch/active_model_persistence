# frozen_string_literal: true

RSpec.describe ActiveModelPersistence::Indexable do
  context "for a model that includes indexable with an index on the 'id' attribute" do
    let(:model_class_with_id_index) do
      Class.new do
        include ActiveModelPersistence::Indexable
        attribute :id, :integer
        attribute :name, :string
        attribute :manager_id, :integer, default: nil

        index :id, unique: true
      end
    end

    let(:model_class_with_id_and_manager_id_index) do
      Class.new do
        include ActiveModelPersistence::Indexable
        attribute :id, :integer
        attribute :name, :string
        attribute :manager_id, :integer, default: nil

        index :id, unique: true
        index :manager_id
      end
    end

    let(:o1) { model_class.new(id: 1, name: 'James', manager_id: 3) }
    let(:o2) { model_class.new(id: 2, name: 'Frank', manager_id: 3) }
    let(:o3) { model_class.new(id: 3, name: 'Boss') }

    describe '.index' do
      context 'when an id index is defined' do
        let(:model_class) { model_class_with_id_index }
        it 'should create the id index in the model class' do
          expect(model_class.indexes[:id]).to be_a(ActiveModelPersistence::Index)
        end
      end
      context 'when an id and manager_id index is defined' do
        let(:model_class) { model_class_with_id_and_manager_id_index }
        it 'should create two indexes' do
          expect(model_class.indexes.size).to eq(2)
        end
        it 'should create the id index in the model class' do
          expect(model_class.indexes[:id]).to be_a(ActiveModelPersistence::Index)
        end
        it 'should create the manager_id index in the model class' do
          expect(model_class.indexes[:manager_id]).to be_a(ActiveModelPersistence::Index)
        end
      end
    end

    describe '.update_indexes' do
      context 'with just an id index' do
        let(:model_class) { model_class_with_id_index }

        context 'when an object is added to the index' do
          before do
            model_class.update_indexes(o1)
          end
          it 'should be able to fetch the object by id' do
            expect(model_class.find_by_id(1).first).to eq(o1)
          end
        end
      end

      context 'with both an id and manager id index' do
        let(:model_class) { model_class_with_id_and_manager_id_index }

        before do
          model_class.update_indexes(o1)
        end

        it 'should be able to fetch the object by id' do
          expect(model_class.find_by_id(1).first).to eq(o1)
        end

        it 'should be able to fetch the object by manager_id' do
          expect(model_class.find_by_manager_id(3)).to eq([o1])
        end
      end
    end

    describe '.remove_from_indexes' do
      context 'with just an id index' do
        let(:model_class) { model_class_with_id_index }

        context 'when an object is added to the index and then removed from the index' do
          before do
            model_class.update_indexes(o1)
            model_class.remove_from_indexes(o1)
          end
          it 'should not be able to fetch the object by id' do
            expect(model_class.find_by_id(1).first).to be_nil
          end
        end
      end

      context 'with both an id and manager id index' do
        let(:model_class) { model_class_with_id_and_manager_id_index }

        context 'when an object is added to the index and then removed from the index' do
          before do
            model_class.update_indexes(o1)
            model_class.remove_from_indexes(o1)
          end

          it 'should not be able to fetch the object by id' do
            expect(model_class.find_by_id(1).first).to be_nil
          end

          it 'should not be able to fetch the object by manager_id' do
            expect(model_class.find_by_manager_id(1)).to be_empty
          end
        end
      end
    end

    describe '#update_indexes' do
      let(:model_class) { model_class_with_id_index }

      context 'when an object is added to the id index' do
        before do
          o1.update_indexes
        end
        it 'should be able to find the objects by id' do
          expect(model_class.find_by_id(1).first).to eq(o1)
        end
      end

      context 'when two objects are added to the id index' do
        before do
          o1.update_indexes
          o2.update_indexes
        end
        it 'should be able to find both objects by id' do
          expect(model_class.find_by_id(1).first).to eq(o1)
          expect(model_class.find_by_id(2).first).to eq(o2)
        end
      end
    end

    describe '#remove_from_indexes' do
      let(:model_class) { model_class_with_id_and_manager_id_index }

      context 'when three objects are added to the id and manager_id indexes' do
        before do
          o1.update_indexes
          o2.update_indexes
          o3.update_indexes
        end
        context 'when object1 is removed from the indexes' do
          before do
            o1.remove_from_indexes
          end
          it 'should not be able to find object1 by id' do
            expect(model_class.find_by_id(1)).to be_empty
          end

          it 'should be able to find object2 by id' do
            expect(model_class.find_by_id(2).first).to eq(o2)
          end

          it 'should be able to find object3 by id' do
            expect(model_class.find_by_id(3).first).to eq(o3)
          end

          it 'should not be able to find object1 by manager_id' do
            expect(model_class.find_by_manager_id(3)).not_to include(o1)
            expect(model_class.find_by_manager_id(3)).to include(o2)
          end
        end
      end
    end
  end
end
