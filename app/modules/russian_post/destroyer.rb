module RussianPost
  class Destroyer
    include Virtus.model strict: true

    attribute :order, Order

    include Virtus.model strict: true

    def perform
      RussianPost.logger.info "Выполняю удаление заказа с почты #{order.id}.."
      client = RussianPost::Client.new(
        token: order.delivery_type.russian_post_token,
        key: order.delivery_type.russian_post_key
      )

      data = [order.order_delivery.russian_post_id]

      res = JSON.parse client.delete(data).body

      raise RussianPost::ResponseError.new(res['errors']) if res['errors'].present?

      order.order_delivery.update! russian_post_id: nil
      RussianPost.logger.info "Удаление заказа с почты успешно завершено #{order.id}.."
    rescue StandardError => e
      Bugsnag.notify e, metaData: { order_id: order.id }
      RussianPost.logger.error "Заказ #{order.id}. Ошибка: #{e}"
      raise e
    end
  end
end
