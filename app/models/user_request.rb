class UserRequest < ApplicationRecord
  include HasAdminComments
  extend Enumerize

  UTM_FIELDS = %i[utm_source utm_campaign utm_medium utm_term utm_content].freeze

  FIELDS = %i[phone name email referer opts] + UTM_FIELDS

  serialize :opts

  # validates :phone, presence: true
  validates :name, presence: true
  validates :email, presence: true, email: true

  scope :no_manager, -> { where manager_id: nil }
  scope :no_vendor,  -> { where vendor_id: nil }
  scope :no_referer, -> { where "referer is null or referer = ''" }

  belongs_to :manager, class_name: 'AdminUser'
  belongs_to :vendor

  before_create do
    self.clean_phone = get_clean_phone
  end

  # enumerize :state, in: [:fresh, :female], default: :fresh

  after_create do
    message = "Заявка на подключение: #{self}"
    SupportMailer.support_mail(message).deliver_later!
  end

  def last_comment
    admin_comments.first
  end

  def to_s
    [name, phone, email].compact.join ' '
  end

  def get_clean_phone
    PhoneUtils.clean_phone phone
  end
end
