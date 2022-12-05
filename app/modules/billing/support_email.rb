module Billing
  module SupportEmail
    SupportEmailNotification = Class.new StandardError

    def support_email(message)
      mail_message = "Внимание!\nМагазин #{vendor.try(:home_url) || '???'} пополнил баланс на #{transaction.amount}.\n#{message}\nСсылка на транзакцию: #{transaction.billing_url}"

      SupportMailer.sos_mail(mail_message, subject: 'Поступила оплата').deliver_later!

      Bugsnag.notify(
        SupportEmailNotification.new(message),
        metaData: {
          mail_message: mail_message,
          url: transaction.billing_url,
          amount: transaction.amount,
          transaction_id: transaction.id,
          vendor_id: transaction.vendor.try(:id)
        }
      )
    end
  end
end
