class Seeds::SqlDumpLoad
  LIST_OF_TABLES = %w[admin_users ar_internal_metadata authors books
                      books_authors books_genres books_keywords folders
                      genre_groups genres keywords languages schema_migrations]
  include Callable
  extend Dry::Initializer

  option :filename, type: Dry::Types['strict.string']

  def call
    return unless File.exist?(filename)

    drop_tables
    load_sql_dump

    true
  end

  def drop_tables
    LIST_OF_TABLES.each do |table|
      ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS #{table} CASCADE"
    end
  end

  def load_sql_dump
    config = Rails.application.config_for(:database)
    params = "-h #{config.dig(:primary, :host)} -p #{config.dig(:primary, :port)} -U #{config.dig(:primary, :username)}"

    `PGPASSWORD=#{config.dig(:primary, :password)} psql #{params} #{config.dig(:primary, :database)} < #{filename}`
  end
end
