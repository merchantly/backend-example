require 'rails_helper'

RSpec.describe Operator::MailTemplatesController, type: :controller do
  include OperatorControllerSupport

  let!(:mail_template) { create :mail_template, vendor: vendor }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'GET new' do
    it 'returns http success' do
      get :new
      expect(response.status).to eq 302
    end
  end

  describe 'GET show' do
    it 'redirects' do
      get :show, params: { id: mail_template.to_param }
      expect(response.status).to eq 200
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: mail_template.to_param }
      expect(response.status).to eq 200
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(MailTemplate).to receive :update!
      patch :update, params: { id: mail_template.to_param, mail_template: { subject: 'some' } }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(MailTemplate).to receive :destroy!
      delete :destroy, params: { id: mail_template.to_param }
      expect(response.status).to eq 302
    end
  end
end
