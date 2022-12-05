require 'rails_helper'

RSpec.describe Operator::WelcomePageController, type: :controller do
  include OperatorControllerSupport

  let!(:welcome_category) { create :category, vendor: vendor }

  it :show do
    get :show
    expect(response.status).to eq 200
  end

  it do
    expect(vendor.theme.show_short_details).to be_truthy
  end

  it :update do
    put :update, params: { vendor: { welcome_category_id: welcome_category.id, theme_attributes: { show_short_details: false } } }
    expect(response.status).to eq 200
    expect(vendor.theme.reload.show_short_details).to be_falsey
  end
end
