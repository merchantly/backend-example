class VendorSmsIncome < ApplicationRecord
  belongs_to :vendor

  validates :count, presence: true, numericality: { only_integer: true }
  validates :comment, presence: true

  before_update do
    raise 'Нельзя изменять'
  end

  before_destroy do
    raise 'Нельзя удалить'
  end

  before_create do
    vendor.update_attribute :sms_count, vendor.sms_count + count
    true
  end
end
