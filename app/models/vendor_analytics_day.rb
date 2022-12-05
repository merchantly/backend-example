class VendorAnalyticsDay < ApplicationRecord
  belongs_to :vendor

  scope :by_week, ->(date) { where 'date>=? and date<=?', date.beginning_of_week, date.end_of_week }
  scope :by_date, ->(date) { where date: date }
  scope :summary, -> { select('sum(orders_count) as orders_count, sum(product_views_count) as product_views_count, sum(carts_count) as carts_count') }

  def self.upsert(vendor_id:, date:, product_views_count: 0, orders_count: 0, carts_count: 0)
    sql = %{
      INSERT INTO #{table_name}
      (vendor_id, date, product_views_count, orders_count, carts_count)
      VALUES (#{vendor_id}, '#{date}', #{product_views_count}, #{orders_count}, #{carts_count})
      ON CONFLICT (vendor_id, date) DO UPDATE SET
      product_views_count = #{table_name}.product_views_count + #{product_views_count}, orders_count = #{table_name}.orders_count + #{orders_count}, carts_count = #{table_name}.carts_count + #{carts_count}
    }

    connection.execute sql
  end
end
