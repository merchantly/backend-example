module CommerceML
  # Протокол обмена: http://v8.1c.ru/edi/edi_stnd/131/
  #
  class BaseExchangeController < ApplicationController
    include CurrentVendor

    FILE_LIMIT = 20.megabytes
    COOKIE_NAME = 'exchange'.freeze

    CommerceMlForbiddenError = Class.new StandardError
    rescue_from CommerceMlForbiddenError, with: :rescue_forbidden_error

    skip_before_action :verify_authenticity_token

    before_action :authentication_check
    before_action :authorize_cookie, except: %i[checkauth unknown]
    before_action :configuration_check

    # A. Начало сеанса
    # Выгрузка данных начинается с того, что система "1С:Предприятие" отправляет http-запрос следующего вида:
    # http://<сайт>/<путь> /1c_exchange.php?type=catalog&mode=checkauth.
    #
    # В ответ система управления сайтом передает системе «1С:Предприятие» три строки (используется разделитель строк "\n"):
    #
    # слово "success";
    # имя Cookie;
    # значение Cookie.
    # Примечание. Все последующие запросы к системе управления сайтом со стороны "1С:Предприятия" содержат в заголовке запроса имя и значение Cookie
    def checkauth
      CommerceML.logger.info "checkauth vendor_id=#{current_vendor.id}"

      exchange_record = create_exchange_record
      exchange_response "success\n#{COOKIE_NAME}\n#{exchange_record.cookie_value}"
    end

    # B. Запрос параметров от сайта
    #
    # Далее следует запрос следующего вида:
    # http://<сайт>/<путь> /1c_exchange.php?type=catalog&mode=init
    #
    # В ответ система управления сайтом передает две строки:
    #
    # 1. zip=yes, если сервер поддерживает обмен в zip-формате -  в этом случае на следующем шаге файлы должны быть упакованы в zip-формате
    # или
    # zip=no - в этом случае на следующем шаге файлы не упаковываются и передаются каждый по отдельности.
    #
    # 2. file_limit=<число>, где <число> - максимально допустимый размер файла в байтах для передачи за один запрос. Если системе "1С:Предприятие" понадобится передать файл большего размера, его следует разделить на фрагменты.
    def init
      CommerceML.logger.info "init vendor_id=#{current_vendor.id}"

      exchange_record.update_status! :init
      exchange_response "zip=yes\nfile_limit=#{FILE_LIMIT}"
    end

    # D. Отправка файла обмена на сайт
    #
    # Затем система "1С:Предприятие" отправляет на сайт запрос вида
    # http://<сайт>/<путь> /1c_exchange.php?type=sale&mode=file&filename=<имя файла>,
    # который загружает на сервер файл обмена, посылая содержимое файла в виде POST.
    #
    # В случае успешной записи файла система управления сайтом передает строку со словом "success". Дополнительно на следующих строчках могут содержаться замечания по загрузке.
    #
    # Примечание. Если в ходе какого-либо запроса произошла ошибка, то в первой строке ответа системы управления сайтом будет содержаться слово "failure", а в следующих строкÐ°х - описание ошибки, произошедшей в процессе обработки запроса.
    #  Если произошла необрабатываемая ошибка уровня ядра продукта или sql-запроса, то будет возвращен html-код.
    def file
      # Заказы приходят так приходят так:
      # request.content_type == "application/octet-stream"
      CommerceML.logger.info "file vendor_id=#{current_vendor.id} file=#{params[:filename]}"

      exchange_record.add_file! filename: params[:filename], file: request.body
      exchange_response 'success'

      # Примечание. Если в ходе какого-либо запроса произошла ошибка, то в первой строке ответа системы управления сайтом будет содержаться слово "failure",
      # а в следующих строках - описание ошибки, произошедшей в процессе обработки запроса.
      # Если произошла необрабатываемая ошибка уровня ядра продукта или sql-запроса, то будет возвращен html-код.
    end

    def unknown
      CommerceML.logger.error "Не известный type и mode #{params.to_h} [#{request.method}] vendor=#{current_vendor.id}"

      exchange_response 'failure'
    end

    private

    def authentication_check
      authenticate_or_request_with_http_basic do |name, password|
        ActiveSupport::SecurityUtils.variable_size_secure_compare(name, configuration.login) &
          ActiveSupport::SecurityUtils.variable_size_secure_compare(password, configuration.password)
      end
    end

    def authorize_cookie
      raise "Wrong cookie #{cookie_value}" unless exchange_record
    end

    def configuration_check
      raise "empty configuration for vendor #{current_vendor.name}" if configuration.blank?
    end

    def exchange_record
      @exchange_record ||= find_exchange_record
    end

    def find_exchange_record
      exchange_record_class.find_by(cookie_value: cookie_value)
    end

    def cookie_value
      cookies[COOKIE_NAME]
    end

    def exchange_response(message)
      CommerceML.logger.info "CommerceML Exchange response #{message.inspect}"
      render plain: message
    end

    def configuration
      @configuration ||= build_configuration
    end

    def build_configuration
      current_vendor.commerce_ml_configuration || raise(CommerceMlForbiddenError)
    end

    def create_exchange_record
      raise 'Create exchange record'
    end

    def exchange_record_class
      raise 'Not implemented exchange_record_class'
    end

    def rescue_forbidden_error
      render plain: 'Forbidden', status: :forbidden
    end
  end
end
