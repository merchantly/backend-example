class ProductOrderingService
  class State
    include Virtus.model strict: true

    # Продается?
    attribute :is_ordering, Boolean

    # Причина почему не продается в том, что его нет в наличии?
    attribute :is_run_out,  Boolean

    attribute :info, Hash

    attribute :ordering_quantity_state, Symbol

    attribute :has_price, Boolean

    def errors
      @errors ||= build_errors
    end

    def humanized_errors
      # Исключаем not_sellable, потому что он тупо говорит "Не продаваемый", нас интересуют причины
      buffer = errors.reject { |e| %i[not_sellable].include?(e) }
      buffer = buffer.reject { |e| e == :run_out } if buffer.include? :no_quantity
      buffer.map do |key|
        I18n.t key, scope: %i[helpers product_state_errors]
      end
    end

    private

    def build_errors
      list = info.values.reject { |v| v == :ok }
      # Если и так много разныз причин, не зачем писать общую (:fail)
      list.delete :fail if list.many?
      list
    end
  end

  # @param <Product||ProductItem>
  #
  def initialize(good)
    @good = good
    @state = nil
  end

  delegate :is_run_out, :is_ordering, to: :state

  def state
    @state ||= build_state
  end

  private

  attr_reader :good

  delegate :vendor, to: :good

  def build_state
    # https://bugsnag.com/brandymint/kiiiosk-dot-com/errors/553a602bd4b5f4b0e48d8d47?event_id=555b43efe943e26723f6c13e#stacktrace
    # Для того чтобы избежать wrong number of arguments (-1 for 0..1)
    # создаем параметры заранее
    attrs = {
      is_ordering: ordering?,
      is_run_out: !ordering_quantity?,
      info: info,
      ordering_quantity_state: ordering_quantity_state,
      has_price: has_price?
    }

    State.new attrs
  end

  def info
    hash = {}
    %i[ordering_quantity_state has_price_state sellable_state ordering_state].each { |k| hash[k] = send k }
    hash
  end

  # Можно заказать, все параметры позволяют?
  #
  #
  def ordering?
    ordering_state == :ok
  end

  def ordering_state
    @ordering_state ||= build_ordering_state
  end

  def build_ordering_state
    if good.is_a?(ProductItem) || good.ordering_as_product_only?
      build_good_ordering_state
    elsif good.goods.select(&:is_ordering).any?
      :ok
    else
      :has_no_orderable_goods
    end
  end

  def build_good_ordering_state
    if !sellable?
      :not_sellable
    elsif !ordering_quantity?
      :no_quantity
    elsif !has_price?
      :no_price
    elsif IntegrationModules.enable?(:ecr) && Settings.vat_required && good.vat.nil?
      :no_vat
    elsif IntegrationModules.enable?(:ecr) && Settings.vat_required && good.purchase_price.nil?
      :no_purchase_price
    elsif !period_orderable?
      :no_period_ordering
    else
      :ok
    end
  end

  # Цена позволяет купить?
  #
  #
  def has_price?
    has_price_state == :ok
  end

  def has_price_state
    @has_price_state ||= build_has_price_state
  end

  def build_has_price_state
    if good.actual_price.present? && good.actual_price.to_f.positive?
      :ok
    else
      :no_price
    end
  end

  # Технически его можно купить?
  #
  #
  def sellable?
    sellable_state == :ok
  end

  def sellable_state
    @sellable_state ||= build_sellable_state
  end

  def build_sellable_state
    if !good.is_a?(ProductItem) && !good.viewable?
      return :unpublished
    end

    if vendor.order_stocking_only?
      if !good.stock_linked?
        return :no_stock_linked
      elsif !good.consignment_linked?
        return :no_consignment_linked
      end
    end

    if vendor.vendor_amocrm.present? && vendor.vendor_amocrm.is_active? && !vendor.vendor_amocrm.enable_sale_not_linked? && good.amocrm_catalog_element_id.nil?
      return :no_amocrm_link
    end

    :ok
  end

  # Количество позволяет товар купить?
  #
  #
  def ordering_quantity?
    %i[ok orderable_infinity].include? ordering_quantity_state
  end

  def ordering_quantity_state
    @ordering_quantity_state ||= build_ordering_quantity_state
  end

  def build_ordering_quantity_state
    if good.quantity_infinity?
      if good.sellable_infinity?
        :orderable_infinity
      else
        :not_orderable_infinity
      end
    elsif good.total_quantity.to_f.positive?
      :ok
    else
      :run_out
    end
  end

  # Ordering period
  #
  #
  def period_orderable?
    return true if good.ordering_start_at.blank? && good.ordering_end_at.blank?

    current_time = Time.zone.now

    return false if good.ordering_start_at.present? && (current_time < good.ordering_start_at)
    return false if good.ordering_end_at.present? && (current_time > good.ordering_end_at)

    true
  end
end
