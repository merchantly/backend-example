# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :mail_template do
    key { MailTemplate::CLIENT_METHODS.sample }
    namespace { 'client' }
    vendor { create :vendor }
    locale { I18n.default_locale }
    subject { 'MyString' }

    content_sms { 'MyText' }
    content_html { 'MyText' }
    content_text { 'MyText' }
  end
end
