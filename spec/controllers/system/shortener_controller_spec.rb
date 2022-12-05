require 'rails_helper'

RSpec.describe System::ShortenerController, type: :controller do
  let(:short_link) { create :short_link }

  describe 'GET #show' do
    it 'returns http success' do
      get :show, params: { id: short_link.slug }
      expect(response).to be_redirection
    end
  end
end
