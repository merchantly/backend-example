class Reporters::SalesTop < Reporters::SalesBase
  def top_five_selling_categories
    top_five(:category, :selling)
  end

  def top_five_grossing_categories
    top_five(:category, :grossing)
  end

  def top_five_selling_items
    top_five(:item, :selling)
  end

  def top_five_grossing_items
    top_five(:item, :grossing)
  end

  private

  attr_reader :vendor, :filter

  def top_five(property, type)
    top_first(property, type, 5)
  end

  def top_first(property, type, count = 1)
    top(property, type).first(count).to_h
  end

  def top_last(property, type, count = 1)
    top(property, type).last(count).to_h
  end

  def top(property, type)
    scope = order_items.group(:good_id, :good_type)

    result = case type
             when :selling
                scope.sum(:count)
             when :grossing
                scope
                  .sum('order_items.price_cents * order_items.count')
                  .transform_values { |cents| Money.new cents, vendor.default_currency }
             else
                raise("Unknown type #{type}")
              end

    result.transform_keys! do |k|
      if k.first.present?
        k.second.constantize.find(k.first)
      else
        nil
      end
    end

    case property
    when :item
      result.transform_keys { |k| k.present? ? k.title : 'Custom Amount' }
    when :category
      h = {}

      result.each do |k, v|
        h[k.category] ||= 0

        h[k.category] += v
      end

      h.transform_keys { |k| k.present? ? k.title : 'No category' }
    else
      raise "Unknown property #{property}"
    end.sort_by(&:second).reverse.to_h
  end
end
