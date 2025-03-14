class Book < ApplicationRecord
  include Ransackable

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  has_many :books_authors, dependent: :destroy
  has_many :authors, through: :books_authors
  accepts_nested_attributes_for :authors

  has_many :books_genres, dependent: :destroy
  has_many :genres, through: :books_genres
  accepts_nested_attributes_for :genres

  has_many :books_keywords, dependent: :destroy
  has_many :keywords, through: :books_keywords
  accepts_nested_attributes_for :keywords

  belongs_to :folder # , counter_cache: :books_count
  belongs_to :language # , counter_cache: :books_count

  validates :title, :libid, :size, :filename, presence: true

  PUBLIC_FIELDS = %w[id del ext filename folder_id id_value insno
                     language_id libid series serno size title
                     published_at updated_at created_at]
  RANSACK_ASSOCIATIONS = %w[authors books_authors books_genres books_keywords
                            folder genres keywords language]

  settings index: { number_of_shards: 1, number_of_replicas: 0 } do
    mappings dynamic: 'false' do
      indexes :id, type: 'keyword'
      indexes :title, type: 'text', analyzer: 'standard'
      indexes :series, type: 'text', analyzer: 'standard'
      # indexes :libid, type: 'integer'
      # indexes :size, type: 'integer'
      # indexes :filename, type: 'keyword'
      # indexes :del, type: 'boolean'
      # indexes :ext, type: 'keyword'
      indexes :published_at, type: 'date'
      indexes :folder_id, type: 'keyword'
      indexes :language_id, type: 'keyword'

      indexes :author, type: 'text', analyzer: 'standard'
      indexes :category, type: 'keyword'
      indexes :pages, type: 'integer'
    end
  end

  def as_indexed_json(options = {})
    as_json(only: [:title, :author, :category, :published_at])
  end
end
