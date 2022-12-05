require 'rails_helper'

RSpec.describe System::MailsController, type: :controller do
  let(:operator) { create :operator, :has_vendor }
  let(:vendor) { operator.vendors.first }
  let(:system_mail_template) { create :system_mail_template }
  let(:system_mail_delivery) { create :system_mail_delivery, system_mail_template: system_mail_template }
  let(:system_mail_recipient) do
    create :system_mail_recipient, delivery: system_mail_delivery, operator: operator, vendor: vendor
  end

  describe 'GET logo' do
    it 'returns http success' do
      expect(system_mail_recipient.open_at).to eq nil
      get :logo, params: { mail_recipient_gid: system_mail_recipient.to_global_id.to_param }
      expect(response.status).to eq 200
      expect(system_mail_recipient.reload.open_at).not_to eq nil
    end
  end

  describe 'GET show' do
    it 'returns http success' do
      get :show, params: { id: system_mail_recipient.to_global_id.to_param }
      expect(response.status).to eq 200
    end

    it 'check follow link' do
      expect(system_mail_recipient.follow_link_at).to eq nil
      get :show, params: { id: system_mail_recipient.to_global_id, follow_link: 'some', mail_recipient_gid: system_mail_recipient.to_global_id.to_param }
      expect(system_mail_recipient.reload.follow_link_at).not_to eq nil
    end
  end
end
