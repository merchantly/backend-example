class ZeroAdder
  def self.perform(value, max_length)
    zeros_count = max_length - value.length

    return value if zeros_count.zero?

    (0..zeros_count - 1).map { '0' }.join + value
  end
end
