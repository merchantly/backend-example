require 'rails_helper'

RSpec.describe 'Оператор создает товар', :vcr, type: :feature do
  let!(:vendor)   { create :vendor, :with_w1_auth, sellable_infinity: false }
  let!(:member)   { create :member, vendor: vendor }

  let(:product_title) { 'Майка футбольная' }
  let(:product_price) { Money.new(123) }
  let(:product_quantity) { 12 }

  it 'добавляет один товар' do
    # Stage 1 - Заходим на страницу создания товарв
    visit new_operator_product_path
    expect(page).to have_current_path new_operator_product_path, ignore_query: true

    # pending 'pending on vexor' if ENV['USER'] == 'vexor'

    # Stage 2 - Добавлям товар, но без цены, он сохраняется
    within '#new_product' do
      fill_in 'product[custom_title_ru]', with: product_title

      click_button I18n.t('shared.save')
    end

    # После сохранения нас перекидывает на страницу списка товаров
    expect(html).to include 'цена не установлена'
    expect(page).to have_current_path operator_products_path, ignore_query: true

    # Находим свой товар в списке и переходим на страницу редактирования
    click_link product_title

    # Видим сообщение почему товар не продается
    expect(page.text).to include 'Не установлен остаток, Нет цены'
    expect(page.text).to include 'Нет цены'
    expect(page.text).to include 'Закончился'

    # Добавляем недостающие данные

    within '.edit_product' do
      fill_in 'product[quantity]', with: product_quantity
    end

    # click_link 'Цены'
    # click_button 'Добавить цену'
    fill_in 'product[product_prices_attributes][0][price]', with: product_price.to_f

    click_button I18n.t('shared.save')

    expect(page).to have_current_path operator_products_path, ignore_query: true
    expect(html).not_to include 'Цена не известна'

    # Видим цену уже со скидкой
    expect(html).to include humanized_money_with_currency product_price

    # Снова идем на страницу товара
    click_link product_title

    # На странице товара больше никаких алертов нет
    expect(has_no_css?('.alert')).to be_truthy
  end
end
