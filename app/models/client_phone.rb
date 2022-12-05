class ClientPhone < ApplicationRecord
  belongs_to :client
  belongs_to :vendor

  scope :unconfirmed, -> { where confirmed: false }
  validates :phone, phone: true, uniqueness: { scope: :vendor_id }

  before_save :normalize_phone

  before_save do
    self.vendor ||= client.vendor
  end

  def to_s
    phone
  end

  def marked_for_destruction?
    !confirmed? && super
  end

  def confirm!
    update_columns confirmed: true, confirmed_at: Time.zone.now
  end

  private

  def normalize_phone
    self.phone = Phoner::Phone.parse(phone).to_s
  end
end
