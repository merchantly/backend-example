module VendorOperators
  extend ActiveSupport::Concern

  included do
    has_many :operators, through: :members
  end

  def basic_operator
    operators.first
  end

  def add_member(operator, role)
    members.create! operator: operator, role: role
  end
end
