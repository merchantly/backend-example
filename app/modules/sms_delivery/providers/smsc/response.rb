# https://smsc.ru/api/http/

# ======= Коды ошибок ========
# 1	Ошибка в параметрах.
# 2	Неверный логин или пароль.
# 3	Недостаточно средств на счете Клиента.
# 4	IP-адрес временно заблокирован из-за частых ошибок в запросах. Подробнее
# 5	Неверный формат даты.
# 6	Сообщение запрещено (по тексту или по имени отправителя).
# 7	Неверный формат номера телефона.
# 8	Сообщение на указанный номер не может быть доставлено.
# 9	Отправка более одного одинакового запроса на передачу SMS-сообщения либо более пяти одинаковых запросов на получение стоимости сообщения в течение минуты.

# ======== Пример ========
# <result>
# <error>описание</error>
# <error_code>N</error_code>
# <id>id сообщения</id>
# </result>

module SmsDelivery
  module Providers
    module Smsc
      class Response
        include HappyMapper

        FATAL_ERRORS = [1, 2, 3, 4, 5].freeze

        tag :result
        # описание ошибки
        element :error, String

        element :error_code, Integer
        element :id, String
        element :cnt, String

        def self.fake
          new
        end

        def success?
          error_code.present?
        end

        def fail?
          !success?
        end

        def error_message
          error
        end

        def fatal_error?
          error_code.present? && FATAL_ERRORS.include?(error_code)
        end

        def soft_error?
          !fatal_error?
        end

        def raw
          to_xml(Nokogiri::XML::Builder.new(encoding: 'UTF-8')).to_xml
        end
      end
    end
  end
end
