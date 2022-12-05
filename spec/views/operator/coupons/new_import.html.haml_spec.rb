require 'rails_helper'

RSpec.describe 'operator/coupons/new_import', type: :view do
  before do
    def view.current_operator_locale
      :en
    end
  end

  it do
    expect do
      render_described
    end.not_to raise_error
  end
end
