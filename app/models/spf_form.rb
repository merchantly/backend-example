class SpfForm
  include Virtus.model
  include ActiveModel::Model

  attribute :email, String
  validates :email, presence: true, email: true

  def domain
    email.to_s.split('@').last
  end
end
