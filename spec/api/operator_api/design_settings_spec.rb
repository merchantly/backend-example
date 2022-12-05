require 'rails_helper'

describe OperatorAPI::DesignSettings do
  include OperatorRequests
  let!(:vendor) { create :vendor, :with_w1_auth, :with_theme }

  context do
    let(:params) { { pageBgColor: '#fe1234' } }

    it do
      put '/operator/api/v1/design_settings', params: params
      assert response.successful?, 'реультат ответа не OK'
      assert_equal vendor.theme.reload.page_bg_color, params[:pageBgColor]
    end
  end

  it do
    get '/operator/api/v1/design_settings'
    assert response.ok?, 'реультат ответа не OK'
  end
end
