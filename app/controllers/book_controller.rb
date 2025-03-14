class BookController < ApplicationController
  def index
    page = params[:page].to_i
    page = 1 if page < 1
    items_per_page = Settings.app.items_per_page
    # books = Book.offset((page - 1) * items_per_page).limit(items_per_page)

    search_query = { match_all: {} }
    response = Book.__elasticsearch__.search(
      query: search_query,
      from: (page - 1) * items_per_page,
      size: items_per_page
    )

    books = response.records

    render json: books.to_json
    # render json: BookResource.new(books).serialize
  end
end
