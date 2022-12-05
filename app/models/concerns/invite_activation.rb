module InviteActivation
  extend ActiveSupport::Concern

  def accept!(operator)
    vendor.members.create! operator: operator, role: role rescue ActiveRecord::RecordInvalid
    destroy!
  end

  def find_and_bind_operators
    w = {}
    w[:email] = email if email.present?
    w[:phone] = phone if phone.present?

    operators = Operator.where(w).to_a

    if operators.blank?
      if Settings::Features.invite_auto_create_operator
        operators << Operator.create!(email: email, phone: phone, name: name)
      else
        return []
      end
    end

    operators.map do |o|
      vendor.members.create(operator: o, role: role, position: position) && o
    end
  end
end
