class VendorAnalyticsSessionProduct < ApplicationRecord
  belongs_to :product
  belongs_to :vendor

  def self.upsert(vendor_id:, datetime:, product_id:, session_id:, views_count: 0, orders_count: 0, carts_count: 0)
    sql = %{
      INSERT INTO #{table_name}
      (vendor_id, datetime, product_id, session_id, views_count, orders_count, carts_count)
      VALUES (#{vendor_id}, '#{datetime}', #{product_id}, '#{session_id}', #{views_count}, #{orders_count}, #{carts_count})
      ON CONFLICT (vendor_id, datetime, product_id, session_id) DO UPDATE SET
      views_count = #{table_name}.views_count + #{views_count}, orders_count = #{table_name}.orders_count + #{orders_count}, carts_count = #{table_name}.carts_count + #{carts_count}
    }

    connection.execute sql
  end
end
