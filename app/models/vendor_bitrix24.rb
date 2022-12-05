class VendorBitrix24 < ApplicationRecord
  belongs_to :vendor

  has_many :access_tokens, class_name: 'Bitrix24::AccessToken'

  belongs_to :responsible_manager, class_name: 'Member'

  def add_log(str)
    update log: "#{log}#{str}\n"
  end
end
