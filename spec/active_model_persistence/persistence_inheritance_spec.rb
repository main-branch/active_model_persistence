# frozen_string_literal: true

require 'json'

RSpec.describe ActiveModelPersistence::Persistence do
  context 'when included in a model' do
    let!(:user_class) do
      Class.new do
        include ActiveModelPersistence::Persistence

        attribute :short_id, :string
        attribute :name, :string

        self.primary_key = 'short_id'

        index :name

        validates :short_id, presence: true
      end
    end

    let!(:customer_class) do
      Class.new(user_class) do
        attribute :birthday, :date
        index :birthday, unique: false
      end
    end

    let!(:employee_class) do
      Class.new(user_class) do
        attribute :hr_id, :integer
        index :hr_id, unique: true
      end
    end

    describe 'with user, customer and employee classes' do
      context 'with two users, two customers and two employees' do
        before do
          user_class.create!(short_id: 'johnu', name: 'John User')
          user_class.create!(short_id: 'janeu', name: 'Jane User')
          customer_class.create!(short_id: 'johnc', name: 'John Customer', birthday: Date.new(1980, 1, 1))
          customer_class.create!(short_id: 'janec', name: 'Jane Customer', birthday: Date.new(1980, 1, 2))
          employee_class.create!(short_id: 'johne', name: 'John Employee', hr_id: 1)
          employee_class.create!(short_id: 'janee', name: 'Jane Employee', hr_id: 2)
        end

        it 'should find all users when search via the user class' do
          expect(user_class.find('johnu')).not_to be_nil
          expect(user_class.find('janeu')).not_to be_nil
          expect(user_class.find('johnc')).not_to be_nil
          expect(user_class.find('janec')).not_to be_nil
          expect(user_class.find('johne')).not_to be_nil
          expect(user_class.find('janee')).not_to be_nil
        end

        it 'should only find employees when searching via the employee class' do
          expect(employee_class.find('johnu')).to be_nil
          expect(employee_class.find('janeu')).to be_nil
          expect(employee_class.find('johnc')).to be_nil
          expect(employee_class.find('janec')).to be_nil
          expect(employee_class.find('johne')).not_to be_nil
          expect(employee_class.find('janee')).not_to be_nil
        end

        it 'should only find customers when searching via the customer class' do
          expect(customer_class.find('johnu')).to be_nil
          expect(customer_class.find('janeu')).to be_nil
          expect(customer_class.find('johnc')).not_to be_nil
          expect(customer_class.find('janec')).not_to be_nil
          expect(customer_class.find('johne')).to be_nil
          expect(customer_class.find('janee')).to be_nil
        end

        describe '.count' do
          it 'user_class.count should return 6' do
            expect(user_class.count).to eq(6)
          end

          it 'employee_class.count should return 2' do
            expect(employee_class.count).to eq(2)
          end

          it 'customer_class.count should return 2' do
            expect(customer_class.count).to eq(2)
          end
        end

        describe '.all' do
          it 'user_class.all should return all objects' do
            expect(user_class.all.map(&:short_id)).to match(%w[johnu janeu johnc janec johne janee])
          end
          it 'employee_class.all should return only employee objects' do
            expect(employee_class.all.map(&:short_id)).to match(%w[johne janee])
          end
          it 'customer_class.all should return all customer objects' do
            expect(customer_class.all.map(&:short_id)).to match(%w[johnc janec])
          end
        end

        describe '.delete_all' do
          it 'user_class.delete_all should delete all objects' do
            user_class.delete_all
            expect(user_class.count).to be_zero
          end

          it 'employee_class.delete_all should only delete employee objects' do
            employee_class.delete_all
            expect(user_class.all.map(&:short_id)).to match(%w[johnu janeu johnc janec])
            expect(employee_class.count).to be_zero
            expect(customer_class.all.map(&:short_id)).to match(%w[johnc janec])
          end

          it 'customer_class.delete_all should only delete customer objects' do
            customer_class.delete_all
            expect(user_class.all.map(&:short_id)).to match(%w[johnu janeu johne janee])
            expect(employee_class.all.map(&:short_id)).to match(%w[johne janee])
            expect(customer_class.count).to be_zero
          end
        end
      end
    end
  end
end
