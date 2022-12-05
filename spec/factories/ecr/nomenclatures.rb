FactoryBot.define do
  factory :nomenclature, class: '::Ecr::Nomenclature' do
    purchase_price { 1.to_money vendor.try(:default_currency).try(:iso_code) }
    vat { 10 }
    quantity { 0 }
    quantity_unit { create :quantity_unit, vendor: vendor }
    title { 'Nomenclature' }
  end
end
