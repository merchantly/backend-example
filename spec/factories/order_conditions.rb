# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :order_condition do
    vendor
    vendor_delivery { nil }
    vendor_payment { nil }
    enter_workflow_state { nil }
    enter_finite_state { nil }
    action { %i[delivery reserve unreserve].sample }
    event { %i[on_create on_workflow_change on_pay_success on_pay_failure].sample }
    after_time_minutes { 1 }
    notification_template { 'client:reminder_payment' }
  end
end
