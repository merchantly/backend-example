class VendorProductAnalyticsDay < ApplicationRecord
  belongs_to :vendor
  belongs_to :product

  scope :by_week, ->(date) { where 'date>=? and date<=?', date.beginning_of_week, date.end_of_week }
  scope :by_date, ->(date) { where date: date }
  scope :by_top, ->(count = 5) { order('orders_count desc, carts_count desc, views_count desc').limit(count) }

  def self.upsert(vendor_id:, date:, product_id:, views_count: 0, orders_count: 0, carts_count: 0)
    sql = %{
      INSERT INTO #{table_name}
      (vendor_id, product_id, date, views_count, orders_count, carts_count)
      VALUES (#{vendor_id}, #{product_id}, '#{date}', #{views_count}, #{orders_count}, #{carts_count})
      ON CONFLICT (vendor_id, product_id, date) DO UPDATE SET
      views_count = #{table_name}.views_count + #{views_count}, orders_count = #{table_name}.orders_count + #{orders_count}, carts_count = #{table_name}.carts_count + #{carts_count}
    }

    connection.execute sql
  end
end
