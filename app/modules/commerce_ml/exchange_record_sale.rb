class CommerceML::ExchangeRecordSale < ApplicationRecord
  belongs_to :order
  belongs_to :exchange_record, class_name: 'CommerceML::ExchangeRecord'
end
