class Ecr::RefundOrderItem < ApplicationRecord
  self.table_name = :ecr_refund_order_items

  belongs_to :operator
  belongs_to :ecr_document, class_name: 'Ecr::Document'
  belongs_to :order
  belongs_to :order_item
end
