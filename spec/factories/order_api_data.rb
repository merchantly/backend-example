FactoryBot.define do
  factory :order_api_data, class: Hash do
    sequence :user do |n|
      { address: "Адрес #{n}", phone: '+79011232828', comment: "Комментарий #{n}", name: "Имя #{n}", email: 'test@test.ru' }
    end

    initialize_with { attributes }
  end
end
