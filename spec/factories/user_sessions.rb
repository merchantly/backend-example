FactoryBot.define do
  factory :user_session, class: 'Session' do
    session_id { generate :uuid }
    data { {} }
  end
end
