module RFMAnalytics
  class ClientSegmentizer
    include Virtus.model strict: true
    attribute :client, Client
    attribute :vendor_rfm, VendorRfm

    def segmentize
      RFMAnalytics::ClientSegments.new(
        r: client_recency,
        f: client_frequency,
        m: client_money
      )
    end

    private

    delegate :count, :recencies, :moneys, :frequencies, to: :vendor_rfm

    def client_recency
      count.times.each do |i|
        return i + 1 if client.recency <= recencies[i]
      end

      count
    end

    def client_frequency
      count.times.each do |i|
        return i + 1 if client.orders_count >= frequencies[i]
      end

      count
    end

    def client_money
      total_orders_price = client.total_orders_price.exchange_to client.vendor.default_currency
      count.times.each do |i|
        return i + 1 if total_orders_price >= moneys[i]
      end

      count
    end
  end
end
