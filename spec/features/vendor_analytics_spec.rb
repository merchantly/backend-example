require 'rails_helper'

RSpec.describe 'Аналитика покупок и посещений', type: :feature do
  include ActionView::Helpers::TextHelper
  include CurrentVendor
  include OrderingSteps

  let!(:vendor) { create :vendor, :with_theme, :payments_and_deliveries }
  let(:utm_source) { 'source1' }
  let(:utm_medium) { 'medium' }
  let(:referer) { 'https://google.com/referer' }
  let(:utm) { UtmEntity.new utm_source: utm_source, utm_medium: utm_medium }
  let(:price)         { Money.new 12_345 }
  let(:package_price) { Money.new 10_000 }
  let(:count)         { 5 }
  let(:total_price)   { price * count }
  let(:total_price_with_package) { (price * count) + package_price }
  let(:free_delivery_threshold)  { vendor.vendor_deliveries.last.free_delivery_threshold }

  let!(:product)          { create :product, :ordering, price: price, vendor: vendor, quantity: count * 2 }
  let!(:package_category) { create :category, vendor: vendor }

  let!(:coupon)       { create :coupon_single, vendor: vendor }
  let!(:coupon_code)  { coupon.code }

  before do
    Capybara.app_host = vendor.home_url
    set_current_vendor vendor
  end

  before do
    VendorAnalyticsVisitor.delete_all
    VendorAnalyticsVisit.delete_all
    VendorAnalyticsSource.delete_all
    allow(Settings).to receive(:save_analytics).and_return true

    Capybara.current_session.driver.header 'Referer', referer
  end

  it 'приходит по какой-то рекламе' do
    VCR.use_cassette :analytics do
      visit "/?utm_source=#{utm_source}&utm_medium=#{utm_medium}"
    end

    expect(VendorAnalyticsVisitToSource).to have(2).items
    expect(VendorAnalyticsSourceUtm).to have(1).items
    expect(VendorAnalyticsSourceUtm.first.utm_entity).to eq utm

    expect(VendorAnalyticsSourceReferer).to have(1).items
    expect(VendorAnalyticsSourceReferer.first.referer).to eq referer
    # visit_product_and_add_to_cart
    # visit_cart
    # visit_order_page

    # expect(find_field(:vendor_order_phone).value).to be_blank
    # expect(find_field(:vendor_order_name).value).to be_blank
    # expect(find_field(:vendor_order_email).value).to be_blank
    # expect(find_field(:vendor_order_city_title).value).to be_blank
    # expect(find_field(:vendor_order_address).value).to be_blank

    ## Заказываем
    # fill_fields
    # click_button I18n.t('vendor.order.next')

    # expect(page).to have_content I18n.t('vendor.order.created.title')
    # expect(page).to have_content 'Ваш заказ'

    ## Видим цену уже со скидкой
    # expect(page).to have_content humanized_money_with_currency(Money.new(49_380)).sub('.', ',')

    ## Проверяем, что данные покупателя сохранились в сессии
    # visit_product_and_add_to_cart

    # visit_cart
    # visit_order_page

    # expect(page).to have_content humanized_money_with_currency(total_price).sub('.', ',')

    # expect(find_field(:vendor_order_phone).value).to eq '+79033891228'
    # expect(find_field(:vendor_order_name).value).to eq 'Вася'
    # expect(find_field(:vendor_order_email).value).to eq 'aaa@example.com'
    # expect(find_field(:vendor_order_city_title).value).to eq 'Москва'
    # expect(find_field(:vendor_order_address).value).to eq 'Шумилова 21'

    ## TODO: Удалить выбранную ранее доставку/оплату, обновить страницу, и убедиться, что по умолчанию выбрана другая

    # click_button I18n.t('vendor.order.next')
    # text = I18n.t 'vendor.order.free_delivery_text_html', free_delivery_threshold: humanized_money_with_currency(free_delivery_threshold).sub('.', ',').to_s
    # expect(page).to have_content strip_tags text
  end
end
