module OrderingSteps
  def visit_product_and_add_to_cart
    # Stage 1 - заходим на страницу товара
    visit vendor_product_path(product)

    # Добавляем в коорзину
    click_button I18n.t('vendor.button.to_cart')

    expect(page).to have_text I18n.t('vendor.flashes.good_added_to_basket', title: product.title)
  end

  def visit_cart
    # Stage 2 - Идем в корзину
    visit vendor_cart_path

    # Общая сумма равна стоимости единственного товара
    expect(find(:css, '.b-cart__total-sum').find(:css, '>span:last-child').text).to eq humanized_money_with_currency(price)

    select count, from: "cart[items][#{Cart.last.items.first.id}][count]"
    expect(find(:css, "[name='cart[items][#{Cart.last.items.first.id}][count]']").value).to eq count.to_s
  end

  def visit_order_page
    # Stage 3 - Переходим на оформление заказа
    click_button I18n.t('vendor.order.submit')

    expect(page).to have_content I18n.t 'vendor.pages.titles.order'
  end

  def fill_fields
    within '#new_vendor_order' do
      fill_in :vendor_order_phone,       with: '+79033891228'
      fill_in :vendor_order_name,        with: 'Вася'
      fill_in :vendor_order_email,       with: 'aaa@example.com'
      fill_in :vendor_order_city_title,  with: 'Москва'
      fill_in :vendor_order_address,     with: 'Шумилова 21'

      fill_in :vendor_order_coupon_code, with: coupon_code
    end
  end

  def select_package
    find(:css, "#cart_package_good_global_id_#{package.global_id}").set true
  end

  def accept_public_offer
    find(:css, '#vendor_order_public_offer_accepted').set true
  end
end
