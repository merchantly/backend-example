FactoryBot.define do
  factory :tag do
    vendor
    sequence :title do |n|
      "tag #{n}"
    end
  end
end
