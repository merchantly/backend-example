class OrderDeliveryRussianPost < OrderDelivery
  def self.model_name
    superclass.model_name
  end

  def delivery
    RussianPostWorker.perform_async order_id
  end

  def cancel_with_error!(error)
    cancel!
    update! error: error
  end

  def can_start_delivery?
    true
  end

  def tracking_id
    nil
  end
end
