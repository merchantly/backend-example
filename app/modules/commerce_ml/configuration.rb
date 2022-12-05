class CommerceML::Configuration < ApplicationRecord
  self.table_name = 'commerce_ml_configurations'

  belongs_to :vendor

  validates :login, :password, presence: true
end
