class AdminUser < ApplicationRecord
  include OperatorAccessKey
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable
  ROLES = %i[superadmin operator].freeze

  has_many :vendors, foreign_key: :manager_id

  scope :managers, -> { all }
  scope :with_role, ->(role) { where(role: role) }
  # scope :none, -> { where(:id => nil).where("id IS NOT ?", nil) }

  def to_s
    name
  end

  def password=(value)
    super value if value.present?
  end

  # Закоменчено тк в багснаге ловим ошибку при изменении пароля: super no superclass method `password_confirmation=' for #<AdminUser:0x00006260590ace38>
  # def password_confirmation=(value)
  #   super value if value.present?
  # end

  def name
    super.presence || email
  end

  def superadmin?
    role == 'superadmin'
  end

  def can_sort?(_arg)
    true # TODO fix auth
  end
end
