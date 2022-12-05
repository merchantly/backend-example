require 'rails_helper'

describe React::FPanel::PropsBuilder do
  include CurrentVendor
  subject do
    described_class.new vendor: vendor, filter: products_filter
  end

  let!(:vendor) { build :vendor }
  let(:products_filter) { VendorProductsFilter.new }

  before do
    set_current_vendor vendor
  end

  it do
    expect(subject.build).to eq(
      options: [],
      selectedOptions: [],
      params: {},
      filterUrl: nil,
      isFilterToggleVisible: false,
      filterApplyType: 'notice',
      showFilterClearButton: false
    )
  end

  context 'vendor with common filter options' do
    let!(:vendor) { build :vendor, :with_common_filter_options }

    it do
      expect(subject.build).to eq(
        options: [
          {
            title: 'Доступность', type: 'radio', paramName: 'availability', value: 'any', default: 'any',
            items:
              [
                { name: 'Все', paramValue: 'any' },
                { name: 'Распродажа', paramValue: 'sale' },
                { name: 'В наличии', paramValue: 'in-stock' },
                { name: 'Под заказ', paramValue: 'on-request' }
              ]
          }
        ],
        selectedOptions: [],
        params: {},
        filterUrl: nil,
        isFilterToggleVisible: false,
        filterApplyType: 'notice',
        showFilterClearButton: false
      )
    end
  end
end
