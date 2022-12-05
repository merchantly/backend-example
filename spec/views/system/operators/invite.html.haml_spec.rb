require 'rails_helper'

RSpec.describe 'system/operators/invite', type: :view do
  subject do
    render template: template, locals: { operator: operator, invite_key: invite_key, invite: invite }
  end

  let!(:invite) { create :invite }
  let(:operator)   { Operator.build_from_invite invite }
  let(:invite_key) { invite.try :key }
  let(:vendor)     { invite.vendor }
  let(:template)   { 'system/operators/invite' }

  it 'renders form' do
    subject
    expect(view).to render_template template
    expect(rendered).to match 'invite_key'
    expect(rendered).to match invite.key
    expect(rendered).to match invite.email
    expect(rendered).to match vendor.active_domain_unicode
  end
end
