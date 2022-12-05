require 'rails_helper'

RSpec.describe SlugRedirect, type: :model do
  let!(:vendor)       { create :vendor }
  let(:category)      { create :category, vendor: vendor }
  let(:path)          { '/some' }
  let(:redirect_path) { category.public_path }

  it 'при создании slug_redirect соответствующий history_path удаляется' do
    create :history_path, vendor: vendor, path: path
    create :slug_redirect, path: path, redirect_path: redirect_path, resource: category

    expect(HistoryPath.count).to eq 0
  end

  describe 'создание' do
    context 'путь равен редиректу' do
      it 'должен бросать ошибку' do
        expect { create :slug_redirect, path: redirect_path, redirect_path: redirect_path, resource: category }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
