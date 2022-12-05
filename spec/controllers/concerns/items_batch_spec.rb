require 'rails_helper'

RSpec.describe Operator::ProductsController, type: :controller do
  include OperatorControllerSupport

  describe '#batch' do
    let(:ids) { [1, 2, 3] }
    let(:action) { :some_action }

    it '#batch' do
      expect(controller).to receive(:perform_batch_action)

      post :batch, params: { batch_action: action, selected_items_ids: ids.to_json }
      expect(response.status).to eq(204)
    end
  end
end
