module OrderCommerceMl
  extend ActiveSupport::Concern

  included do
    has_many :exchange_record_sales, class_name: 'CommerceML::ExchangeRecordSale'
    has_many :exchange_records, class_name: 'CommerceML::ExchangeRecord', through: :exchange_record_sales
  end
end
