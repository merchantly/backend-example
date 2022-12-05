FactoryBot.define do
  factory :system_mail_delivery do
    system_mail_template
    sequence :title do |n|
      "system mail delivery #{n}"
    end
    state { :draft }
  end
end
