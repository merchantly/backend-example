require 'securerandom'
module OperatorAccessKey
  extend ActiveSupport::Concern

  included do
    before_create :generate_access_key
  end

  def regenerate_access_key!
    update_column :access_key, generate_access_key
  end

  private

  def generate_access_key
    self.access_key = SecureRandom.hex 32
  end
end
