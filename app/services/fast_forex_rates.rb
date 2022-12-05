class FastForexRates
  include Virtus.model

  URL = 'https://api.fastforex.io/fetch-multi'.freeze

  attribute :currencies, Array[String]

  def perform
    return if Secrets.fast_forex.blank?

    response = Faraday.get(URL, from: :USD, to: currencies.join(', '), api_key: Secrets.fast_forex.api_key)

    result = JSON.parse response.body

    result['results']
  end
end
