require 'rails_helper'

RSpec.describe System::SessionsController, type: :controller do
  before do
    request.host = 'app.test.host'
  end

  it 'обычная ситуация' do
    get :new
    expect(response.status).to eq(200)
  end

  it 'google/yandex webmaster' do
    request.headers['Accept'] = '*/*'
    get :new
    expect(response.status).to eq(200)
  end

  it 'мамкины хакиры ver1' do
    get :new, format: 'php'
    expect(response.status).to eq(415)
  end

  it 'мамкины хакиры ver2' do
    get :new, format: ''
    expect(response.status).to eq(415)
  end

  it 'мамкины хакиры ver3' do
    request.headers['Accept'] = 'image/gif, image/x-xbitmap, image/jpeg,image/pjpeg, application/x-shockwave-flash,application/vnd.ms-excel,application/vnd.ms-powerpoint,application/msword'
    get :new
    expect(response.status).to eq(415)
  end
end
