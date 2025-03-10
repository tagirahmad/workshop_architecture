require 'rails_helper'

RSpec.describe BookController, type: :controller do
  describe 'GET #index' do
    let(:items_per_page) { 5 }
    let!(:books) { create_list(:book, 10) }

    before do
      allow(Settings.app).to receive(:items_per_page).and_return(items_per_page)
    end

    context 'when page parameter is not provided' do
      it 'returns the first page of books' do
        get :index
        expect(response).to have_http_status(:success)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response.size).to eq(items_per_page)
        expect(parsed_response.map { |b| b['id'] }).to match_array(books.first(items_per_page).map(&:id))
      end
    end

    context 'when page parameter is provided' do
      it 'returns the correct page of books' do
        get :index, params: { page: 2 }
        expect(response).to have_http_status(:success)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response.size).to eq(items_per_page)
        expect(parsed_response.map { |b| b['id'] }).to match_array(books.last(items_per_page).map(&:id))
      end
    end

    context 'when page parameter is less than 1' do
      it 'defaults to the first page' do
        get :index, params: { page: 0 }
        expect(response).to have_http_status(:success)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response.size).to eq(items_per_page)
        expect(parsed_response.map { |b| b['id'] }).to match_array(books.first(items_per_page).map(&:id))
      end
    end

    context 'when there are fewer books than the requested page can contain' do
      it 'returns an empty result for pages beyond the last one' do
        get :index, params: { page: 3 }
        expect(response).to have_http_status(:success)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_empty
      end
    end
  end
end