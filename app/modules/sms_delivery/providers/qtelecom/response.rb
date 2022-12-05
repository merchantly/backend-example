# http://go.qtelecom.ru/_support/_articles/view_http/

# ======= Коди ошибок =======
# -20117 Неправильный номер телефона.
# -20170 Слишком большой текст сообщения. Максимальная длина не должна превышать 160 байт.
# -20171 Не пройдена проверка текста сообщения на наличие недопустимых слов и/или фраз.
# -20158 Отправитель или получатель в черном списке.
# -20167 Сработало ограничение по отправке одинакового текста на один и тот же номер в течение небольшого промежутка времени. Обратитесь в поддержку, если хотите отключить или уменьшить период.
# -20144 Нет доступного тарифа для запрашиваемого направления.
# -20147 Нет подходящего тарифа у вышестоящего контрагента.
# -20174 Политика маршрутизации не найдена.
# -20154 Ошибка транспорта. При возникновении этой ошибки обратитесь в службу поддержки.
# -20148 Не поддерживаемое направление. # обычно это неверный номер - Невозможно предоставить услуги для продукта "1:721083510302:1"
# -20163 Отправитель не разрешен

# ======= Пример =======
# <output>
# <result>
#    <sms post_id="x124127456" id="99991" smstype="SENDSMS"  phone="+79999999991" sms_res_count="1"><![CDATA[Привет]]></sms>
#    <sms post_id="x124127456" id="99992"  smstype="SENDSMS"  phone="+79999999992" sms_res_count="1"><![CDATA[Привет]]></sms>
# </result>
# <errors>
#    <error code="-20117" post_id="x124127456">Неправильный номер телефона: +7999999999999</error>
# </errors>
# </output>

module SmsDelivery
  module Providers
    module Qtelecom
      class Response
        include HappyMapper
        FATAL_ERRORS = [
          -20_158, -20_144, -20_147, -20_174, -20_154, -20_163, -20_135, -20_167
        ].freeze

        class Result
          include HappyMapper
          class Sms
            include HappyMapper

            attribute :id, Integer
            attribute :post_id, String
            attribute :smstype, String
            attribute :phone, String
            attribute :sms_res_count, Integer

            # content :text, String, xpath: './/text()'
            element :text, String, xpath: './/text()'
          end

          has_many :sms, Sms
        end

        class Errors
          include HappyMapper
          class Error
            include HappyMapper

            attribute :code, Integer
            attribute :post_id, String

            content :text, String, xpath: './/text()'
          end

          has_many :error, Error
        end

        tag :output
        has_one :errors, Errors
        has_one :result, Result

        def self.fake
          new
        end

        def success?
          errors.blank? || errors.error.count.zero?
        end

        def fail?
          !success?
        end

        def error_message
          errors.present? ? errors.error.map(&:text).flatten.join(', ') : nil
        end

        def fatal_error?
          errors.present? && (errors.error.map { |e| e.try(:code) }.flatten.compact & FATAL_ERRORS).any?
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
