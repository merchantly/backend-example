require 'rails_helper'

RSpec.describe 'system/operators/new', type: :view do
  subject do
    render template: template, locals: { operator: operator }
  end

  let(:operator) { Operator.new }
  let(:template) { 'system/operators/new' }

  it 'renders form' do
    subject
    expect(view).to render_template template
  end
end
