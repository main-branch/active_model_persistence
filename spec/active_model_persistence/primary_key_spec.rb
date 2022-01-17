# frozen_string_literal: true

RSpec.describe ActiveModelPersistence::PrimaryKey do
  let(:model_class) do
    Class.new do
      include ActiveModelPersistence::PrimaryKey
      attribute :id, :integer
      attribute :username, :string
    end
  end

  before do
    @object = model_class.new(id: 1, username: 'couballj')
  end

  describe '.primary_key' do
    subject { model_class.primary_key }
    context 'with the default primary key' do
      it { is_expected.to eq('id') }
    end
  end

  describe '.primary_key=' do
    subject { model_class.primary_key }
    context 'when the primary key is changed to `username`' do
      before do
        model_class.primary_key = 'username'
      end
      it { is_expected.to eq('username') }
    end
  end

  describe '#primary_key' do
    context 'when the primary key is mapped to the default `id` attribute' do
      it 'should return the value of the `id` attribute' do
        expect(@object.primary_key).to eq(1)
      end
    end
    context 'when the primary key is mapped to the `username` attribute' do
      before do
        model_class.primary_key = 'username'
      end
      it 'should return the value of the `username` attribute' do
        expect(@object.primary_key).to eq('couballj')
      end
    end
  end

  describe '#primary_key=' do
    context 'when the primary key is mapped to the default `id` attribute' do
      it 'should set the value of the `id` attribute' do
        @object.primary_key = 2
        expect(@object.id).to eq(2)
      end
    end
    context 'when the primary key is mapped to the `username` attribute' do
      before do
        model_class.primary_key = 'username'
      end
      it 'should set the value of the `username` attribute' do
        @object.primary_key = 'other'
        expect(@object.username).to eq('other')
      end
    end
  end

  describe '#primary_key?' do
    before do
      model_class.primary_key = 'username'
    end
    subject { @object.primary_key? }

    context 'when the primary key is set to a non-nil, non-empty value' do
      it { is_expected.to eq(true) }
    end

    context 'when the primary key is nil' do
      before do
        @object.username = nil
      end
      it { is_expected.to eq(false) }
    end

    context 'when the primary key is an empty string' do
      before do
        @object.username = ''
      end
      it { is_expected.to eq(false) }
    end
  end
end
