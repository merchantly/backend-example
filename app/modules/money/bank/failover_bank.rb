module Money::Bank
  class FailoverBank < VariableExchange
    def initialize(primary_bank, failover_bank)
      @primary_bank = primary_bank
      @failover_bank = failover_bank
      @broken_rates = {}
    end

    def get_rate(from_cur, to_cur, *args)
      key = "#{from_cur}_#{to_cur}"

      broken_rates[key] || primary_bank.get_rate(from_cur, to_cur, *args)

      # Money::Bank::GoogleCurrencyFetchError
    rescue StandardError => e
      Rails.logger.error "get_rate: #{from_cur}->#{to_cur}: #{e}: #{e.message}"
      rate = failover_bank.get_rate(from_cur, to_cur, *args)

      broken_rates[key] = rate
      rate
    end

    private

    attr_reader :primary_bank, :failover_bank, :broken_rates
  end
end
