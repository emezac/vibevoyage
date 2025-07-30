FactoryBot.define do
  factory :subscription do
    name { "MyString" }
    price { "9.99" }
    status { "MyString" }
    features { "MyText" }
    user { nil }
  end
end
