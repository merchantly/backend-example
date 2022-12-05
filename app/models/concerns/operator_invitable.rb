module OperatorInvitable
  extend ActiveSupport::Concern
  # Используется в форме регистрации
  # По нему идет привязка также, как и по email, телефон
  # Благодаря этому оператор может изменить email/телефон при регистрации
  attr_accessor :invite_key

  included do
    after_commit :activate_invites!, on: :create

    validate :validate_invitation
  end

  def invited_vendor
    invite.try :vendor
  end

  def invite
    @invite ||= Invite.find_by key: invite_key
  end

  def validate_invitation
    return if invite_key.blank?
    return if invite.present?

    errors.add :invite_key, I18n.t('errors.invite.invalid')
  end

  private

  def activate_invites!
    Invite.by_operator(self).each { |i| i.accept! self }
  end
end
