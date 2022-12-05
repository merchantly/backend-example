module GoodItem
  extend ActiveSupport::Concern
  DEFAULT_WEIGHT = 1

  included do
    belongs_to :good, polymorphic: true

    scope :by_good, ->(good) { where good_type: good.class.name, good_id: good.id }

    delegate :image, :article, :product_article, :mandatory_index_image, to: :good, allow_nil: true

    validate do
      if good.present?
        errors.add :good_id, I18n.t('validators.good_item.must_be_good', klass: good.class) unless [Product, ProductItem, ProductUnion].include? good.class

        if good.is_a?(ProductUnion) || (good.is_a?(Product) && good.items.alive.exists?)
          errors.add :good_id, 'You need to specify a product variant'
        end
      end
    end

    alias_attribute :weight, :weight_kg

    delegate :is_digital?, to: :product
  end

  def long_title
    good.try(:long_title) || title
  end

  def product_id
    return if good.blank?

    if good.is_a? ProductItem
      good.product_id
    else
      good.id
    end
  end

  def tax
    TaxCalculator.new(price: total_price, vendor: vendor).perform
  end

  def product_item_id
    return if good.blank?

    good.id if good.is_a? ProductItem
  end

  def smart_quantity
    if selling_by_weight?
      count.to_f * item_weight.to_f
    else
      count
    end
  end

  def total_price
    return if price.nil?

    if selling_by_weight?
      price * count.to_f * item_weight.to_f / weight_of_price
    else
      price * count
    end
  rescue StandardError => e
    Bugsnag.notify e, metaData: { id: id, type: self.class.name, price: price, count: count, item_weight: item_weight }
    price
  end

  def total_purchase_price
    return if purchase_price.nil?

    if selling_by_weight?
      purchase_price * count.to_f * item_weight.to_f / weight_of_price
    else
      purchase_price * count
    end
  end

  def item_weight
    # У некоторых в корзинах для весовых товаров записаны товары без веса.
    # Таким образом исправляем это и предотвращаем в будущем
    if weight.to_f.positive?
      weight
    else
      return nil if product.nil? || product.weight.nil?

      product.weight * count
    end
  end

  def weight=(weight)
    raise 'forbidden to change the weight' unless selling_by_weight?

    super(weight)
  end

  def count=(count)
    raise 'forbidden to change the count' if selling_by_weight? and count.to_i > 1

    super(count)
  end

  def product
    return if good.blank?

    good.is_a?(Product) ? good : good.product
  end
end
