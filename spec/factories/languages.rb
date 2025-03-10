FactoryBot.define do
  factory :language do
    slug { FFaker::Locale.unique.code }
  end

  factory :invalid_language, parent: :language do
    slug { nil }
  end
end
