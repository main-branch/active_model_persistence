# frozen_string_literal: true

RSpec.describe ActiveModelPersistence::Persistence do
  context 'when included in a model' do
    let(:model_class) do
      Class.new do
        include ActiveModelPersistence::Persistence

        attribute :short_id, :string
        attribute :name, :string

        self.primary_key = :short_id

        index :name

        validates :short_id, presence: true
      end
    end

    describe '.new' do
      context 'after creating an object with .new' do
        before do
          @object = model_class.new(short_id: '1', name: 'foo')
        end

        it 'should create a new instance of the model' do
          expect(@object).to be_a(model_class)
          expect(@object).to have_attributes(short_id: '1', name: 'foo')
        end

        it 'should NOT add the object to the short_id index' do
          expect(model_class.find('1')).to be_nil
        end

        it 'should NOT add the object to the name index' do
          expect(model_class.find_by_name('foo')).to be_empty
        end

        it '#new_record? should be true' do
          expect(@object.new_record?).to eq(true)
        end

        it '#destroyed? should be false' do
          expect(@object.destroyed?).to eq(false)
        end

        it '#persisted? should be false' do
          expect(@object.persisted?).to eq(false)
        end
      end
    end

    describe '.create' do
      context 'after creating an object with .create' do
        before do
          @object = model_class.create(short_id: '1', name: 'foo')
        end

        it 'should create a new instance of the model' do
          expect(@object).to be_a(model_class)
          expect(@object).to have_attributes(short_id: '1', name: 'foo')
        end

        it 'should add the object to the short_id index' do
          object = model_class.new(short_id: '1', name: 'foo')
          expect(model_class.find('1')).to eq(object)
        end

        it 'should add the object to the name index' do
          expect(model_class.find_by_name('foo')).to eq([@object])
        end

        it '#new_record? should be false' do
          expect(@object.new_record?).to eq(false)
        end

        it '#destroyed? should be false' do
          expect(@object.destroyed?).to eq(false)
        end

        it '#persisted? should be true' do
          expect(@object.persisted?).to eq(true)
        end
      end

      context 'when given an array of attribute hashs' do
        let(:array_of_attributes) do
          [
            { short_id: '1', name: 'foo' },
            { short_id: '2', name: 'bar' },
            { short_id: '3', name: 'baz' }
          ]
        end
        it 'should create an array of objects' do
          result = model_class.create(array_of_attributes)
          expect(result).to be_a(Array)
          expect(result.size).to eq(3)
          expect(result.map(&:short_id)).to eq(%w[1 2 3])
          expect(result.map(&:name)).to eq(%w[foo bar baz])
        end
      end
    end

    describe '#save' do
      let(:object) { model_class.new(attributes) }
      before do
        @result = object.save
      end
      subject { @result }

      context 'with a valid object' do
        let(:attributes) { { short_id: '1', name: 'foo' } }

        it { is_expected.to eq(true) }

        it 'should save the object' do
          expect(subject).to eq(true)
          expect(object.new_record?).to eq(false)
          expect(object.persisted?).to eq(true)
          expect(model_class.all.size).to eq(1)
          expect(model_class.find('1')).to eq(object)
        end

        it 'should add the object to the primary key index' do
          expect(model_class.find('1')).to eq(object)
        end

        it 'should add the object to the name index' do
          expect(model_class.find_by_name('foo').first.name).to eq(object.name)
        end
      end

      context 'with an invalid object' do
        let(:attributes) { { short_id: nil, name: 'foo' } }

        it { is_expected.to eq(false) }

        it 'should not save the object' do
          expect(object.new_record?).to eq(true)
          expect(object.persisted?).to eq(false)
        end
      end

      context 'with an object that is already persisted and then changed' do
        let(:attributes) { { short_id: '1', name: 'foo' } }
        before do
          object.name = 'bar'
          @result = object.save
        end
        subject { @result }

        it { is_expected.to eq(true) }

        it 'should update the object in the object store' do
          expect(model_class.find('1')).to eq(object)
        end
      end
    end

    describe '.all' do
      subject { model_class.all }

      context 'after creating 3 model objects' do
        let(:array_of_attributes) do
          [
            { short_id: '1', name: 'foo' },
            { short_id: '2', name: 'bar' },
            { short_id: '3', name: 'baz' }
          ]
        end

        before do
          model_class.create(array_of_attributes)
        end

        it 'should return an Enumerator' do
          is_expected.to be_a(Enumerator)
        end

        it 'should return an Enumerator that contains the objects' do
          is_expected.to have_attributes(size: 3)
          expect(subject.map(&:short_id)).to eq(%w[1 2 3])
        end
      end
    end

    describe '.count' do
      subject { model_class.count }
      it 'should start out with zero objects' do
        is_expected.to be_zero
      end

      context 'after creating an object with .new' do
        before do
          model_class.new(short_id: '1', name: 'foo')
        end
        it { is_expected.to be_zero }
      end

      context 'after creating an object with .create' do
        before do
          model_class.create(short_id: '1', name: 'foo')
        end
        it { is_expected.to eq(1) }
      end

      context 'after creating two objects with .create' do
        before do
          model_class.create(short_id: '1', name: 'foo')
          model_class.create(short_id: '2', name: 'bar')
        end
        it { is_expected.to eq(2) }

        context 'after destroying one of the objects' do
          before do
            model_class.find('1').destroy
          end
          it { is_expected.to eq(1) }
        end
      end
    end

    describe '.destroy_all' do
      context 'with three objects' do
        before do
          model_class.create(short_id: '1', name: 'foo')
          model_class.create(short_id: '2', name: 'bar')
          model_class.create(short_id: '3', name: 'baz')
        end

        it 'should have three object in the object store' do
          expect(model_class.size).to eq(3)
        end

        context 'after calling .destroy_all' do
          before do
            model_class.destroy_all
          end

          it 'should remove all objects from the obejct store' do
            expect(model_class.size).to be_zero
          end
        end
      end
    end

    describe '.delete_all' do
      context 'with three objects' do
        before do
          model_class.create(short_id: '1', name: 'foo')
          model_class.create(short_id: '2', name: 'bar')
          model_class.create(short_id: '3', name: 'baz')
        end

        it 'should have three object in the object store' do
          expect(model_class.size).to eq(3)
        end

        context 'after calling .destroy_all' do
          before do
            model_class.delete_all
          end

          it 'should remove all objects from the obejct store' do
            expect(model_class.size).to be_zero
          end
        end
      end
    end
    describe '#destroy' do
      context 'after creating an object with .new and then destroying it' do
        before do
          @object = model_class.new(short_id: '1', name: 'foo')
          @object.destroy
        end

        it '#new_record? should be false' do
          expect(@object.new_record?).to eq(false)
        end

        it '#destroyed? should be true' do
          expect(@object.destroyed?).to eq(true)
        end

        it '#persisted? should be false' do
          expect(@object.persisted?).to eq(false)
        end

        it '#frozen? should be true' do
          expect(@object.frozen?).to eq(true)
        end
      end

      context 'after creating an object with .create and then destroying it' do
        before do
          @object = model_class.create(short_id: '1', name: 'foo')
          @object.destroy
        end

        it 'should remove the object from the list of objects' do
          expect(model_class.object_array.any? { |o| o.id == @object.id }).to eq(false)
        end

        it 'should remove the object from the short_id index' do
          expect(model_class.find('1')).to be_nil
        end

        it 'should remove the object from the name index' do
          expect(model_class.find_by_name('foo')).to be_empty
        end

        it '#new_record? should be false' do
          expect(@object.new_record?).to eq(false)
        end

        it '#destroyed? should be true' do
          expect(@object.destroyed?).to eq(true)
        end

        it '#persisted? should be false' do
          expect(@object.persisted?).to eq(false)
        end
      end

      context 'after finding a previously created object and then destroying it' do
        before do
          @object = model_class.create(short_id: '1', name: 'foo')
          @object = model_class.find('1')
          @object.destroy
        end

        it 'should remove the object from the list of objects' do
          expect(model_class.object_array.any? { |o| o.primary_key == @object.primary_key }).to eq(false)
        end

        it 'should remove the object from the short_id index' do
          expect(model_class.find('1')).to be_nil
        end

        it 'should remove the object from the name index' do
          expect(model_class.find_by_name('foo')).to be_empty
        end

        it '#new_record? should be false' do
          expect(@object.new_record?).to eq(false)
        end

        it '#destroyed? should be true' do
          expect(@object.destroyed?).to eq(true)
        end

        it '#persisted? should be false' do
          expect(@object.persisted?).to eq(false)
        end
      end
    end
  end
end
