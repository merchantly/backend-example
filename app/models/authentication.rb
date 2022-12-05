class Authentication < ApplicationRecord
  belongs_to :authenticatable, polymorphic: true

  serialize :auth_hash

  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :by_uid, ->(uid) { where(uid: uid) }

  validates :provider, presence: true
  validates :uid, presence: true

  delegate :url, :nickname, :avatar_url, :username, :access_token, :expires_at, :expired?, to: :data

  after_create :update_vendor_links, if: :vendored?
  after_destroy :remove_vendor_links, if: :vendored?

  def self.providers
    @providers ||= Authentication.group(:provider).order(:provider).pluck(:provider).map(&:to_sym)
  end

  def vendored?
    authenticatable.is_a? Vendor
  end

  def data
    AuthHashPresenter.new auth_hash
  end

  def to_s
    [provider, uid].join ':'
  end

  def vk_client
    @vk_client ||= VkontakteApi::Client.new access_token
  end

  def profile_url
    case provider.to_sym
    when :facebook
      "http://facebook.com/#{uid}"
    when :vkontakte
      auth_hash['info']['urls']['Vkontakte']
    end
  end

  def info
    OpenStruct.new(auth_hash['info'] || {})
  end

  def image_url
    case provider.to_sym
    when :facebook, :vkontakte
      info.image
    end
  end

  private

  def update_vendor_links
    vendor = authenticatable
    case provider.to_sym
    when :walletone
      vendor.vendor_walletone.update_attribute :merchant_id, uid if vendor.w1_merchant_id.blank?
    end
  end

  def remove_vendor_links
    vendor = authenticatable
    case provider.to_sym
    when :walletone
      vendor.vendor_walletone.update_attribute :merchant_id, nil
    end
  end
end

# <Authentication id: 51, provider: "walletone", uid: "116123546647", auth_hash: {"provider"=>"walletone", "uid"=>116123546647, "info"=>{"user_id"=>116123546647, "name"=>nil}, "credentials"=>{"token"=>"2559215a-9eaa-4284-8055-265513c56d98", "expires"=>"2015-03-27T19:00:04.58Z"}, "extra"=>{"raw_info"=>{"ClientId"=>"kiiiosk.store", "CreateDate"=>"2015-01-26T19:00:04.58Z", "ExpireDate"=>"2015-03-27T19:00:04.58Z", "Scope"=>"GetBalance.CurrencyId(643) GetOperationHistory", "Timeout"=>5184000, "Token"=>"2559215a-9eaa-4284-8055-265513c56d98", "UserId"=>116123546647}}}, created_at: "2015-01-26 19:00:07", updated_at: "2015-01-26 19:00:07", confirmed: false, authenticatable_id: 5, authenticatable_type: "Vendor">
