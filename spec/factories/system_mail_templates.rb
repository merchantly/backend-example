# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :system_mail_template do
    sequence :title do |n|
      "System mail template #{n}"
    end
    subject { 'Hello {{operator.name}}' }

    content { 'MyText<b>{{operator.name}}</b>' }
    template_type { SystemMailTemplate::TYPES.first }
  end

  factory :vendor_notify_mail_template, parent: :system_mail_template, class: 'VendorNotifyMailTemplate' do
    template_type { VendorNotifyMailTemplate::TYPES.first }
  end
end
