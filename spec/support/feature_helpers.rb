module FeatureHelpers
  extend ActiveSupport::Concern

  included do
    def default_url_options(_options = {})
      { locale: nil }
    end
  end

  def operator_login(operator, password = 'password')
    visit system_login_path

    within '#new_operator_login_form' do
      fill_in 'operator_login_form[login]',    with: operator.email
      fill_in 'operator_login_form[password]', with: password

      click_button I18n.t('shared.log_in')
    end

    expect(current_url).to eq vendor.operator_url
  end

  def logged_as(member)
    page.set_rack_session(user_id: member.operator.id)
  end
end
