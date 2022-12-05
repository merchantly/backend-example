module ProductSortableByCategory
  extend ActiveSupport::Concern

  included do
    scope :ordered_by_category, lambda { |category_id, order_direction|
      order(Arel.sql(<<-SQL.squish
        CASE WHEN category_products.category_id = #{category_id} THEN category_products.row_order
        ELSE NULL
        END #{order_direction} NULLS LAST
      SQL
                    ))
    }

    scope :by_category_position, lambda { |category_id, pos|
      joins(:category_products).where('category_products.category_id = ? AND category_products.row_order = ?', category_id, pos)
    }

    scope :without_category_position, lambda { |category_id|
      joins(:category_products).where('category_products.category_id <>', category_id)
    }
  end

  # @param position - порядковый номер элемента в категории, начиная с 0
  def update_position_in_category!(category_id, position)
    update_position_in_category category_id, position
  end

  # @param position - порядковый номер элемента в категории, начиная с 0
  #
  def update_position_in_category(category_id, position)
    case position
    when NilClass
      update_position_in_category category_id, :last
    when String
      update_position_in_category category_id, position.to_i
    else
      category_product = category_products.find_by(category_id: category_id)
      category_product.update_attribute(:row_order_position, position) if category_product.present?
    end
  end

  def ranked_position_in_category(category_id)
    category_products.find_by(category_id: category_id).try(:row_order)
  end

  def position_in_category(category_id)
    over  = 'order by category_products.row_order asc'
    where = "category_products.category_id = #{category_id} and products.archived_at is null and products.product_union_id IS NULL"
    join  = 'JOIN category_products ON category_products.product_id = products.id'
    res = self.class.connection
              .execute("SELECT DISTINCT products.id, row_number() over(#{over}) from products #{join} where #{where}")
              .find { |a| a['id'] == id }
    return nil unless res

    res['row_number'].to_i - 1
  end

  def force_position_in_categories_ids!(cat_ids)
    cat_ids.each do |category_id|
      update_position_in_category! category_id, vendor.default_product_position.to_sym
    end
  end
end
