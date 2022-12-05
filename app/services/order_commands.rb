module OrderCommands
  class Handler
    def initialize(order, author)
      @order    = order
      @commands = Commands.new(@order)
      @author   = author
    end

    def run(command)
      raise "Unknown command #{command}" unless @commands.respond_to? command

      # да, вот таким образом передаем автора. Потому что использоваться он будет где-то в колбеках
      @order.author = @author
      @commands.send command
      @order.author = nil
    end

    def method_missing(command, *_args)
      run command
    end

    def respond_to_missing?(method_name, include_private = false)
      @commands.respond_to?(method_name, include_private) || super
    end
  end

  class Commands
    def initialize(order)
      @order = order
    end

    # Когда мы узначали статус доставки в API агента, оказалось что она
    # в процессе доставки.
    def update_delivery_state_to_delivery!
      # TODO 1. Не менять статус если он уже есть.
      # TODO 2. Не запускать доставку
      #
      order_delivery.delivery!
    end

    # Когда мы узнали статус доставки в API агента, оказалось
    # что она уже доставлена
    def update_delivery_state_to_done!
      order_delivery.done!
    end

    def stop_delivery!
      raise 'Остановка доставки не доступна'
    end

    def start_delivery!
      order_delivery.delivery!
      order_delivery.start_delivery_by_agent!
    end

    def notify_delivery_expired!
      OrderNotificationService.new(order).delivery_expired
      order.update_column :is_delivery_expiration_notified, true
    end

    private

    attr_reader :order

    delegate :order_payment, :order_delivery, to: :order
  end
end
