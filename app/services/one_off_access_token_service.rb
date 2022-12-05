require 'securerandom'
# Одноразовый токен. Удаляется сразу после использования,
# имеент ограниченное время жизни
#
class OneOffAccessTokenService
  EXPIRATION = 5.minutes
  NS = 'one_off_access_tokens'.freeze

  def find(token)
    value = $redis.get key(token)
    $redis.del key(token) if value.present?
    value
  end

  def generate(value)
    token = SecureRandom.hex 32

    $redis.setex key(token), EXPIRATION, value

    token
  end

  private

  def ns
    NS
  end

  def key(token)
    "#{NS}:#{token}"
  end
end
