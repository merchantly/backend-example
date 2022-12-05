class OrderRemoteStock < ApplicationRecord
  belongs_to :order

  def reserve!
    StockReserveWorker.perform_async order_id unless is_reserved?
  end

  def unreserve!
    StockUnreserveWorker.perform_async order_id if is_reserved?
  end
end
