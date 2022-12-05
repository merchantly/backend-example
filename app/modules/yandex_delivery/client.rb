module YandexDelivery
  class Client
    include Virtus.model strict: true

    attribute :data, Hash
    attribute :api_key, String

    def perform
      result = Faraday.post('https://delivery.yandex.ru/api/last/searchDeliveryList', data.merge(secret_key: secret_key))

      json_result = JSON.parse result.body

      raise YandexDelivery::ResponseError.new(json_result['data']) unless json_result['status'] == 'ok'

      json_result['data']
    end

    private

    def secret_key
      Digest::MD5.hexdigest(data.sort.map(&:second).join + api_key)
    end
  end
end
