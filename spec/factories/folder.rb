FactoryBot.define do
  factory :folder do
    name { FFaker::Book.unique.genre }
  end

  factory :invalid_folder, parent: :folder do
    name { nil }
  end

  factory :extract_folder, parent: :folder do
    name { 'fixtures/extract.zip' }
  end
end
