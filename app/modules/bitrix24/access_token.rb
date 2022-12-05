class Bitrix24::AccessToken < ApplicationRecord
  self.table_name = :bitrix24_access_tokens

  belongs_to :vendor_bitrix24

  validates :access_token, :refresh_token, :expires_at, presence: true
end
