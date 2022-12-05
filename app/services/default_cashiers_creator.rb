class DefaultCashiersCreator
  def perform
    base_scope.where(default_cashier_id: nil).find_each do |vendor|
      cashier = vendor.cashiers.create! name: t('default_cashier'), amount_currency: Money.default_currency.iso_code

      vendor.update_column :default_cashier_id, cashier.id
    end

    base_scope.where(default_branch_id: nil).find_each do |vendor|
      branch = vendor.branches.create! name: t('default_branch'), cashier_id: vendor.default_cashier_id

      vendor.update_column :default_branch_id, branch.id
    end
  end

  private

  def t(key, options = {})
    I18n.t key, options.merge(scope: 'services.vendor_registration')
  end

  def base_scope
    Vendor
  end
end
