module VendorW1
  extend ActiveSupport::Concern

  included do
    has_one :vendor_walletone

    scope :by_w1_merchant_id, ->(auth_hash) { joins(:vendor_walletone).where(vendor_walletones: { merchant_id: auth_hash['uid'].to_s }) }
    scope :with_w1, -> { joins(:vendor_walletone).where.not(vendor_walletones: { merchant_id: nil }) }
    scope :without_w1, -> { joins(:vendor_walletone).where.not(vendor_walletones: { merchant_id: nil }) }

    after_create :create_walletone!
  end

  def create_walletone!
    create_vendor_walletone! phone: phone
  end

  def w1_on?
    vendor_walletone.on?
  end

  def w1_merchant_id
    vendor_walletone.merchant_id
  end

  def w1_auth
    authentications.where(uid: vendor_walletone.merchant_id, provider: :walletone).last
  end

  def w1_access_token
    return nil unless w1_auth

    ::AuthHashPresenter.new(w1_auth.auth_hash).access_token
  end

  def w1_access_token_expires_at
    date = w1_auth.try :expires_at
    date.present? ? Date.parse(date) : nil
  end

  def w1_payment_callback_url
    api_url + "v1/callbacks/w1/payments/#{id}/notify"
  end

  def update_from_auth_hash(auth_hash)
    vendor_walletone.update merchant_id: auth_hash['uid']
  end
end
