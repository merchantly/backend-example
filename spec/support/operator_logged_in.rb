module OperatorLoggedIn
  extend ActiveSupport::Concern
  included do
    let!(:operator) { nil }

    before do
      allow(controller).to receive(:current_operator).and_return operator
      # @request.env['HTTP_REFERER'] = 'http://new.example.com:3000/back'
    end
  end
end
