# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :admin_comment, class: 'ActiveAdmin::Comment' do
    resource { create :order }
    author { create :operator }
    body { 'MyText' }
    namespace { :admin }
  end
end
