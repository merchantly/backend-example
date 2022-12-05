require 'rails_helper'

describe CategoryCountersService::UpdateCounters do
  let(:vendor) { create :vendor }
  let(:product) { create :product, vendor: vendor }
  let(:category) { create :category, vendor: vendor }

  it 'disable strategy' do
    expect(category.products_count).to eq 0
    CategoryCountersService.strategy(CategoryCountersService::Strategies::DISABLE) do
      product.category_ids = product.category_ids + [category.id]
      product.save
    end
    expect(category.reload.products_count).to eq 0
  end

  it 'atomic strategy' do
    expect(category.products_count).to eq 0
    CategoryCountersService.strategy(CategoryCountersService::Strategies::ATOMIC) do
      product.category_ids = [category.id] + product.category_ids
      product.save
    end

    expect(category.reload.products_count).to eq 1
  end

  it 'default strategy' do
    expect(category.products_count).to eq 0
    CategoryCountersService.strategy(CategoryCountersService::Strategies::DEFAULT) do
      product.category_ids = [category.id] + product.category_ids
      product.save
    end

    expect(category.reload.products_count).to eq 1
  end

  it 'run as sidekiq job' do
    expect(category.products_count).to eq 0

    expect(described_class).to receive(:call).with(
      category_ids: array_including([category.id] + product.category_ids)
    ).and_call_original

    CategoryCountersService.strategy(CategoryCountersService::Strategies::ATOMIC, is_sidekiq: true) do
      product.category_ids = product.category_ids + [category.id]
      product.save
    end

    expect(category.reload.products_count).to eq 1
  end
end
