require 'rails_helper'

RSpec.describe 'Проверяем переводы ресурсов у ролей', :vcr, type: :feature do
  let!(:vendor) { create :vendor }
  let!(:member) { create :member, vendor: vendor }
  let!(:role)   { create :role, :with_permissions, vendor: vendor }

  it do
    visit edit_operator_role_path(role)

    # все должно быть переведено
    # т.е. кол-во переводов совпадать с кол-вом элементов в select
    expect(page).to(
      have_selector(
        '.role_permissions_resource_type select option',
        count: I18n.backend.send(:translations)[:ru][:enumerize][:role_permission][:resource_type].count + 1 # в селекте include blank
      )
    )
  end
end
