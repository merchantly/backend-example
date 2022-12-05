module OperatorAuthenticate
  def authenticate(*credentials)
    raise ArgumentError, 'at least 2 arguments required' if credentials.size < 2

    return false if credentials[0].blank?

    if @sorcery_config.downcase_username_before_authenticating
      credentials[0].downcase!
    end

    operator = sorcery_adapter.find_by_credentials credentials

    if operator.respond_to?(:active_for_authentication?) && !operator.active_for_authentication?
      return nil
    end

    set_encryption_attributes

    if operator && @sorcery_config.before_authenticate.all? { |c| operator.send(c) } && operator.valid_credentials?(*credentials)
      block_given? ? yield(operator, nil) : operator
    end
  end
end
