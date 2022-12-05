require 'rails_helper'

RSpec.describe Vendor::BlogPostsController, type: :controller do
  include VendorControllerSupport

  let!(:blog_post) { create :blog_post, vendor: vendor }

  it do
    get :show, params: { id: blog_post.id }
    expect(response).to be_redirect
  end

  it do
    request.path = blog_post.public_path
    get :show, params: { id: blog_post.id }
    expect(response).to be_ok
  end

  it do
    get :index
    expect(response).to be_ok
  end
end
