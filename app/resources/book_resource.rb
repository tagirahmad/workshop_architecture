# frozen_string_literal: true

class BookResource
  include Alba::Resource

  attributes :id, :title, :ext, :filename, :size, :folder_id, :language_id,
             :id_value, :insno, :libid, :series, :serno, :published_at, :created_at, :updated_at

  many :authors do
    attributes :id, :first_name, :last_name
  end

  many :genres do
    attributes :id, :name
  end

  many :keywords do
    attributes :id, :name
  end

  one :folder do
    attributes :id, :name
  end

  one :language do
    attributes :id, :name, :slug
  end
end