require 'rails_helper'

RSpec.describe 'Оператор сбрасывает пароль', type: :feature do
  let!(:vendor_template) { create :vendor_template, :with_precreated_vendors }
  let!(:vendor_template2) { create :vendor_template }
  let!(:email)    { generate :email }
  let!(:phone)    { generate :phone }

  let(:vendor_name)   { 'Шарики' }
  let(:operator_name) { 'Jhown' }
  # let(:ym_client_id) { generate :phone }

  let(:partner) { create :partner }
  let(:partner_coupon) { create :partner_coupon, partner: partner }
  let(:partner_coupon_code) { partner_coupon.code }

  before do
    Capybara.app_host = Rails.application.routes.url_helpers.system_root_url(subdomain: false)
    clear_emails
    allow_any_instance_of(VendorCss).to receive :save
  end

  it 'Регистрируется новый аккаунт (оператор + магазин)' do
    visit new_system_vendor_path

    within '#new_vendor_registration_form' do
      fill_in 'vendor_registration_form[vendor_name]', with: vendor_name
      fill_in 'vendor_registration_form[partner_coupon_code]', with: partner_coupon_code
      click_button I18n.t('shared.next')
    end

    expect(page.body).to have_content 'Выберите шаблон подходящий к Вашей отрасли'

    within "[data-template-id='#{vendor_template.id}']" do
      click_link 'Выбрать'
    end

    expect(current_url).to include choice_template_system_vendors_path

    # find('input#vendor_registration_form_ym_client_id').set ym_client_id

    expect(page.body).to have_content 'Укажите Ваш телефон для авторизации и уведомлений о заказах'

    within '#new_vendor_registration_form' do
      fill_in 'vendor_registration_form[phone]', with: phone
      fill_in 'vendor_registration_form[email]', with: email
      page.check('vendor_registration_form[is_agree]')

      click_button I18n.t('shared.next')
    end

    expect(current_url).to include '/registration-success'

    vendor = Vendor.find_by subdomain: URI.parse(current_url).host.split('.').first
    expect(vendor.partner_coupon_code).to eq partner_coupon.code
    # expect(vendor.ym_client_id).to eq ym_client_id
  end

  it 'Регистрируемся по ссылке с промокодом' do
    visit system_root_path(coupon: partner_coupon.code)

    visit new_system_vendor_path

    within '#new_vendor_registration_form' do
      fill_in 'vendor_registration_form[vendor_name]', with: vendor_name
      click_button I18n.t('shared.next')
    end

    expect(page.body).to have_content 'Выберите шаблон подходящий к Вашей отрасли'

    within "[data-template-id='#{vendor_template.id}']" do
      click_link 'Выбрать'
    end

    expect(current_url).to include choice_template_system_vendors_path

    expect(page.body).to have_content 'Укажите Ваш телефон для авторизации и уведомлений о заказах'

    within '#new_vendor_registration_form' do
      fill_in 'vendor_registration_form[phone]', with: phone
      fill_in 'vendor_registration_form[email]', with: email
      page.check('vendor_registration_form[is_agree]')

      click_button I18n.t('shared.next')
    end

    expect(current_url).to include '/registration-success'

    vendor = Vendor.find_by subdomain: URI.parse(current_url).host.split('.').first
    expect(vendor.partner_coupon_code).to eq partner_coupon.code
  end
end
