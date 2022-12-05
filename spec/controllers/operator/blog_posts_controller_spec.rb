require 'rails_helper'

RSpec.describe Operator::BlogPostsController, type: :controller do
  include OperatorControllerSupport

  let!(:blog_post) { create :blog_post, vendor: vendor }

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response.status).to eq 200
    end
  end

  describe 'GET new' do
    it 'returns http success' do
      get :new
      expect(response.status).to eq 200
    end
  end

  describe 'GET show' do
    it 'redirects' do
      get :show, params: { id: blog_post.id }
      expect(response.status).to eq 302
    end
  end

  describe 'GET edit' do
    it 'returns http success' do
      get :edit, params: { id: blog_post.id }
      expect(response.status).to eq 200
    end
  end

  describe 'POST create' do
    it 'redirects' do
      expect(vendor.blog_posts).to receive :create!
      post :create, params: { blog_post: blog_post.attributes }
      expect(response.status).to eq 302
    end
  end

  describe 'PATCH update' do
    it 'redirects' do
      expect_any_instance_of(BlogPost).to receive :update!
      patch :update, params: { id: blog_post.id, blog_post: { title: 'some' } }
      expect(response.status).to eq 302
    end
  end

  describe 'DELETE destroy' do
    it 'redirects' do
      expect_any_instance_of(BlogPost).to receive :archive!
      delete :destroy, params: { id: blog_post.id }
      expect(response.status).to eq 302
    end
  end
end
