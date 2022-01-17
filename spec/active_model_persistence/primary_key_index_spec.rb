# frozen_string_literal: true

RSpec.describe ActiveModelPersistence::PrimaryKeyIndex do
  let(:model_class) do
    Class.new do
      include ActiveModelPersistence::PrimaryKeyIndex
      attribute :id, :integer
    end
  end

  describe 'find' do
    context 'when a single object with id=1 exists in the indexes' do
      before do
        @object = model_class.new(id: 1)
        @object.update_indexes
      end
      subject { model_class.find(id) }
      context 'when trying to find an object with id=2' do
        let(:id) { 2 }
        it { is_expected.to be_nil }
      end
      context 'when trying to find an object with id=1' do
        let(:id) { 1 }
        it { is_expected.to eq(@object) }
      end
    end
  end
end
