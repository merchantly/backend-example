module OperatorPassword
  def valid_credentials?(login, password)
    (login == email && valid_password?(password)) || (phone == login && (valid_pin_code?(password) || valid_password?(password)))
  end

  def valid_pin_code?(password)
    pin_code == password
  end

  def pin_code
    phone_confirmations.by_phone(phone).first.try(:pin_code)
  end

  def reset_password_url
    Rails.application.routes.url_helpers
         .edit_system_password_reset_url reset_password_token, email: email, phone: phone
  end

  # Переопрееляем sorcery-ский метод, потому что
  # он передает мейлеру в аргументах оператора, вместо ID,
  # а sidekiq этого не любит
  def send_reset_password_email!
    OperatorMailer.reset_password_email(id).deliver!
  end
end
