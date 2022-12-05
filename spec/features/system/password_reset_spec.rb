require 'rails_helper'

RSpec.describe 'Оператор сбрасывает пароль', type: :feature do
  let!(:email)    { generate :email }
  let!(:phone)    { generate :phone }
  let!(:operator) { create :operator, email: email, phone: phone }
  let!(:new_password) { generate :email }

  before do
    Capybara.app_host = Rails.application.routes.url_helpers.system_root_url(subdomain: false)
    clear_emails
  end

  it 'Заходит по емайлу, а пароля не помнит. Запрашивает и восстанавливает' do
    # Stage 1 - заходим на страницу товара
    visit system_login_path

    within '#new_operator_login_form' do
      fill_in 'operator_login_form[login]',    with: email
      fill_in 'operator_login_form[password]', with: 'wrong'

      click_button I18n.t('shared.log_in')
    end

    expect(page).to have_content 'Неверный логин или пин код, введите верные данные'

    click_link 'Восстановить'

    within '#new_reset_form' do
      fill_in 'reset_form[login]', with: email

      click_button 'Получить пароль'
    end

    expect(page).to have_content 'отправлена инструкция для восстановления пароля'
    expect(page).to have_content email

    reset_url = operator.reload.reset_password_url

    # вроде не требуется
    # sleep 0.1

    # Отправляем через sendgrid
    # open_email email
    # expect(links_in_email(current_email).to_s).to include '/password_resets/'

    visit reset_url

    # Вводим новый пароль
    fill_in 'operator[password]', with: new_password
    fill_in 'operator[password_confirmation]', with: new_password

    click_button I18n.t('helpers.submit.update')

    visit system_logout_url

    visit system_login_path

    within '#new_operator_login_form' do
      fill_in 'operator_login_form[login]',    with: email
      fill_in 'operator_login_form[password]', with: new_password

      click_button I18n.t('shared.log_in')
    end

    expect(current_url).to eq system_operator_vendors_url
  end
end
