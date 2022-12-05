class TaggedLogger < SimpleDelegator
  def initialize(tag: nil, logger: nil)
    @tag = tag
    super logger
  end

  %i[info warn debug error].each do |meth|
    define_method meth do |message = 'no message'|
      __getobj__.send meth, prepare_log_message(message) rescue nil
    end
  end

  private

  def prepare_log_message(message)
    message = { message: message } unless message.is_a?(Hash)
    message[:tags] ||= []
    message[:tags] << @tag

    # Боремся с кодирвкой, например при получении запросов из http
    message[:message] = encode_message message[:message]

    message
  end

  def encode_message(message)
    if message.encoding == Encoding::UTF_8
      message
    else
      message.force_encoding('utf-8')
    end
  rescue StandardError
    message.encode
  end
end
