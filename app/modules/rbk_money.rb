module RbkMoney
  CREATE_INVOICE_URL = 'https://api.rbk.money/v1/processing/invoices'.freeze

  PAYMENT_METHODS = %i[
    rbkmoney bankcard exchangers terminals prepaidcard mobilestores
    transfers ibank sberbank svyaznoy euroset contact mts
    uralsib handybank ocean ibankuralsib
  ].freeze
end
