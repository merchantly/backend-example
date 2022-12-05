class CouponsImportService < BaseImportService
  def perform(file:, skip_headers: true)
    super file: file, skip_headers: skip_headers do |row|
      coupon_params = { code: row[0].to_s.strip.chomp, discount: row[1].to_s.strip.chomp, use_count: row[2].to_i }
      vendor.coupon_singles.create! coupon_params
    end
  end
end
