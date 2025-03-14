# namespace :books do
#   desc "Индексация книг из PostgreSQL в Elasticsearch"
#   task reindex: :environment do
#     begin
#       puts "Начинается переиндексация книг..."
#
#       Book.__elasticsearch__.create_index!(force: true)
#       puts "Индекс Elasticsearch для книг успешно создан."
#
#       Book.find_in_batches(batch_size: 10000) do |books|
#         books.each do |book|
#           begin
#             book.__elasticsearch__.index_document
#           rescue => e
#             puts "Ошибка при индексации книги #{book.id}: #{e.message}"
#           end
#         end
#         puts "Пакет из 1000 книг успешно проиндексирован."
#       end
#
#       puts "Индексация завершена успешно!"
#
#     rescue => e
#       puts "Ошибка при выполнении индексации: #{e.message}"
#     end
#   end
# end

namespace :books do
  desc "Индексация книг из PostgreSQL в Elasticsearch"
  task reindex: :environment do
    begin
      puts "Начинается переиндексация книг..."

      Book.__elasticsearch__.create_index!(force: true) unless Book.__elasticsearch__.index_exists?
      puts "Индекс Elasticsearch для книг успешно создан."

      Book.includes(:authors).select(:id, :title, :created_at).find_in_batches(batch_size: 50_000) do |books|
        books_for_import = books.map do |book|
          {
            index: {
              _id: book.id,
              data: {
                title: book.title,
                authors: book.authors.map do |author|
                  [author.last_name, author.first_name, author.middle_name].compact.join(" ")
                end,
                created_at: book.created_at
              }
            }
          }
        end

        begin
          Book.__elasticsearch__.client.bulk({
                                               index: Book.__elasticsearch__.index_name,
                                               body: books_for_import
                                             })
          puts "Пакет из #{books.size} книг успешно проиндексирован."
        rescue => e
          puts "Ошибка при индексации пакета: #{e.message}"
        end
      end

      puts "Индексация завершена успешно!"
    rescue => e
      puts "Ошибка при выполнении индексации: #{e.message}"
    end
  end
end