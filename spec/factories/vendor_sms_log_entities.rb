FactoryBot.define do
  factory :vendor_sms_log_entity do
    message { 'some text' }
    phones { ['+79222222222'] }
    is_success { true }
    sms_count { 1 }
    result { 'dev-ok' }
  end
end
