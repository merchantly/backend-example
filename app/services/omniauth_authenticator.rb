require 'securerandom'

class OmniauthAuthenticator
  include Virtus.model

  attribute :authenticable, Vendor,
            default: ->(auth, _attribute) { Vendor.by_w1_merchant_id(auth.auth_hash).first },
            required: true
  attribute :auth_hash, Hash,
            required: true

  def authentificate
    find || attach || raise_error
  rescue StandardError => e
    binding.debug_error
    Bugsnag.notify e, metaData: { authenticable_id: authenticable.id, provider: provider, uid: uid, auth_hash: auth_hash }
    raise e
  end

  private

  delegate :provider, :uid, to: :auth_hash_p

  def auth_hash_p
    AuthHashPresenter.new auth_hash
  end

  def raise_error
    raise 'Auth is not found and not created'
  end

  def find
    auth = authenticable.authentications.where(provider: provider, uid: uid).first
    return nil if auth.blank?

    auth.update_attribute :auth_hash, auth_hash.as_json
    auth
  end

  def attach
    authenticable.authentications.create! do |a|
      a.provider   = provider
      a.uid        = uid
      a.auth_hash  = auth_hash.as_json
    end
  end
end
