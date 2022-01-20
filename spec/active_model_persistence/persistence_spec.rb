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
      # Since '.create' uses '.save' internally, we don't test the details of '.save' here

      before do
        @result = model_class.create(attributes)
      end
      subject { @result }

      context 'creating a valid object' do
        let(:attributes) { { short_id: '1', name: 'foo' } }

        it { is_expected.to be_a(model_class) }
        it { is_expected.to have_attributes(short_id: '1', name: 'foo', persisted?: true) }

        it 'should add the object to the object store' do
          expect(model_class.find('1')).to eq(subject)
        end

        it 'should add the object to the name index' do
          expect(model_class.find_by_name('foo').first).to eq(subject)
        end

        it '#new_record? should be false' do
          expect(subject.new_record?).to eq(false)
        end

        it '#persisted? should be true' do
          expect(subject.persisted?).to eq(true)
        end

        it '#destroyed? should be false' do
          expect(subject.destroyed?).to eq(false)
        end
      end

      context 'creating an invalid object' do
        let(:attributes) { { short_id: nil, name: nil } }

        it { is_expected.to be_a(model_class) }
        it { is_expected.to have_attributes(short_id: nil, name: nil, persisted?: false) }
      end

      context 'when given an array of attribute hashs to create valid objects' do
        let(:attributes) do
          [
            { short_id: '1', name: 'foo' },
            { short_id: '2', name: 'bar' },
            { short_id: '3', name: 'baz' }
          ]
        end

        it { is_expected.to be_an(Array) }
        it { is_expected.to have_attributes(size: 3) }
        it { is_expected.to all(be_a(model_class)) }
        it { is_expected.to all(have_attributes(short_id: be_a(String), name: be_a(String), persisted?: true)) }

        it 'should have created the objects in the object store' do
          expect(model_class.all.size).to eq(3)
          expect(model_class.find('1')).to eq(subject[0])
          expect(model_class.find('2')).to eq(subject[1])
          expect(model_class.find('3')).to eq(subject[2])
        end
      end
    end

    describe '.create!' do
      # Since '.create!' uses '.save!' internally, we don't test the details of '.save!' here

      before do
        @result = model_class.create!(attributes)
      rescue ActiveModelPersistence::ModelError => e
        @error_raised = e
      end
      subject { @result }
      let(:error_raised) { @error_raised }

      context 'creating a valid object' do
        let(:attributes) { { short_id: '1', name: 'foo' } }

        it { is_expected.to be_a(model_class) }
        it { is_expected.to have_attributes(short_id: '1', name: 'foo') }

        it 'should not raise an error' do
          expect(error_raised).to be_nil
        end

        it 'should add the object to the object store' do
          expect(model_class.find('1')).to eq(subject)
        end

        it 'should add the object to the name index' do
          expect(model_class.find_by_name('foo').first).to eq(subject)
        end

        it '#new_record? should be false' do
          expect(subject.new_record?).to eq(false)
        end

        it '#persisted? should be true' do
          expect(subject.persisted?).to eq(true)
        end

        it '#destroyed? should be false' do
          expect(subject.destroyed?).to eq(false)
        end
      end

      context 'creating an invalid object' do
        let(:attributes) { { short_id: nil, name: nil } }

        it 'should not raise ObjectNotValidError' do
          expect(error_raised).to be_a(ActiveModelPersistence::ObjectNotValidError)
        end
      end

      context 'when given an array of attribute hashs to create valid objects' do
        let(:attributes) do
          [
            { short_id: '1', name: 'foo' },
            { short_id: '2', name: 'bar' },
            { short_id: '3', name: 'baz' }
          ]
        end

        it { is_expected.to be_an(Array) }
        it { is_expected.to have_attributes(size: 3) }
        it { is_expected.to all(be_a(model_class)) }
        it { is_expected.to all(have_attributes(short_id: be_a(String), name: be_a(String))) }

        it 'should have created the objects in the object store' do
          expect(model_class.all.size).to eq(3)
          expect(model_class.find('1')).to eq(subject[0])
          expect(model_class.find('2')).to eq(subject[1])
          expect(model_class.find('3')).to eq(subject[2])
        end
      end
    end

    describe '#save' do
      context 'for a valid object' do
        it 'should return true' do
          object = model_class.new(short_id: '1', name: 'foo')
          expect(object.save).to eq(true)
        end
      end

      context 'for an invalid object' do
        it 'should return false' do
          object = model_class.new(short_id: nil, name: 'foo')
          expect(object.save).to eq(false)
        end
      end
    end

    describe '#save!' do
      let(:object) { model_class.new(attributes) }
      let(:attributes) { { short_id: '1', name: 'foo' } }

      context 'with a new, valid object' do
        before do
          @result = object.save!
        end
        subject { @result }

        it { is_expected.to eq(true) }

        it 'should set new_record? to false' do
          expect(object.new_record?).to eq(false)
        end

        it 'should set persisted? to true' do
          expect(object.persisted?).to eq(true)
        end

        it 'should add the object to the object store' do
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

      context 'with a new, invalid object' do
        let(:attributes) { { short_id: nil, name: 'foo' } }

        it 'should raise an ObjectNotValidError' do
          expect { object.save! }.to raise_error(ActiveModelPersistence::ObjectNotValidError)
        end

        it 'should not change the new_record? state (should be true)' do
          expect { object.save! }.to raise_error(ActiveModelPersistence::ObjectNotValidError)
          expect(object.new_record?).to eq(true)
        end

        it 'should not change the persisted? state (should be false)' do
          expect { object.save! }.to raise_error(ActiveModelPersistence::ObjectNotValidError)
          expect(object.persisted?).to eq(false)
        end

        it 'should not add the object to the object store' do\
          expect { object.save! }.to raise_error(ActiveModelPersistence::ObjectNotValidError)
          expect(model_class.all.size).to be_zero
        end
      end

      context 'with an object that is already persisted and then changed' do
        before do
          object.save
          object.name = 'bar'
          @result = object.save!
        end

        subject { @result }

        it { is_expected.to eq(true) }

        it 'should set new_record? to false' do
          expect(object.new_record?).to eq(false)
        end

        it 'should set persisted? to true' do
          expect(object.persisted?).to eq(true)
        end

        it 'should update the object to the object store' do
          expect(model_class.all.size).to eq(1)
          expect(model_class.find('1').name).to eq('bar')
        end
      end

      context 'with a destroyed object' do
        before do
          object.destroy
        end

        it 'should raise an ObjectDestroyedError' do
          expect { object.save! }.to raise_error(ActiveModelPersistence::ObjectDestroyedError)
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

    describe '#update' do
      context 'for a valid object' do
        it 'should return true' do
          object = model_class.new(short_id: '1', name: 'foo')
          expect(object.update(name: 'bar')).to eq(true)
        end
      end

      context 'for an invalid object' do
        it 'should return false' do
          object = model_class.new(short_id: nil, name: 'foo')
          expect(object.update(name: 'bar')).to eq(false)
        end
      end
    end

    describe '#update!' do
      let(:object) { model_class.new(attributes) }
      let(:attributes) { { short_id: '1', name: 'foo' } }

      context 'with a new, valid object' do
        before do
          @result = object.update!(name: 'bar')
        end
        subject { @result }

        it { is_expected.to eq(true) }

        it 'should set new_record? to false' do
          expect(object.new_record?).to eq(false)
        end

        it 'should set persisted? to true' do
          expect(object.persisted?).to eq(true)
        end

        it 'should set destroyed? to false' do
          expect(object.destroyed?).to eq(false)
        end

        it 'should add the object to the object store' do
          expect(model_class.all.size).to eq(1)
          expect(model_class.find('1')).to eq(object)
        end

        it 'should add the object to the primary key index' do
          expect(model_class.find('1')).to eq(object)
        end

        it 'should add the object to the name index' do
          expect(model_class.find_by_name('bar').first.name).to eq(object.name)
        end
      end

      context 'with a new, invalid object' do
        let(:attributes) { { short_id: nil, name: 'foo' } }

        it 'should raise an ObjectNotValidError' do
          expect { object.update!(name: 'bar') }.to raise_error(ActiveModelPersistence::ObjectNotValidError)
        end

        it 'should not change the new_record? state (should be true)' do
          expect { object.update!(name: 'bar') }.to raise_error(ActiveModelPersistence::ObjectNotValidError)
          expect(object.new_record?).to eq(true)
        end

        it 'should not change the persisted? state (should be false)' do
          expect { object.update!(name: 'bar') }.to raise_error(ActiveModelPersistence::ObjectNotValidError)
          expect(object.persisted?).to eq(false)
        end

        it 'should not change the destroyed? state (should be false)' do
          expect { object.update!(name: 'bar') }.to raise_error(ActiveModelPersistence::ObjectNotValidError)
          expect(object.destroyed?).to eq(false)
        end

        it 'should not add the object to the object store' do
          expect { object.update!(name: 'bar') }.to raise_error(ActiveModelPersistence::ObjectNotValidError)
          expect(model_class.all.size).to be_zero
        end
      end

      context 'with an object that is already persisted and then changed' do
        before do
          object.save
          @result = object.update!(name: 'bar')
        end

        subject { @result }

        it { is_expected.to eq(true) }

        it 'should set new_record? to false' do
          expect(object.new_record?).to eq(false)
        end

        it 'should set persisted? to true' do
          expect(object.persisted?).to eq(true)
        end

        it 'should set destroyed? to false' do
          expect(object.destroyed?).to eq(false)
        end

        it 'should update the object to the object store' do
          expect(model_class.find('1').name).to eq('bar')
        end
      end

      context 'with a destroyed object' do
        before do
          object.destroy
        end

        it 'should raise an ObjectDestroyedError' do
          expect { object.update!(name: 'bar') }.to raise_error(ActiveModelPersistence::ObjectDestroyedError)
        end
      end
    end
  end
end
