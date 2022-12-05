module OperatorRequests
  extend ActiveSupport::Concern

  included do
    let!(:vendor)   { create :vendor, :with_theme, :with_default_cashier }
    let!(:member)   { create :member, vendor: vendor }
    let!(:operator) { member.operator }
    before do
      # Вот так передаем member вместо сессии
      $member = member
      $operator = operator

      host! vendor.operator_host
    end
  end
end
