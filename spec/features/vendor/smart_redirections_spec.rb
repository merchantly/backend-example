require 'rails_helper'

RSpec.describe 'Умный редирект на ресурс со старой ссылки', type: :feature do
  let!(:vendor)   { create :vendor, :with_theme }
  let!(:product)  { create :product, :ordering, vendor: vendor }
  let!(:old_path) { '/old_product' }
  let!(:new_path) { '/new_product' }

  describe do
    before do
      Slug.delete_all
      HistoryPath.delete_all
      Capybara.app_host = vendor.home_url

      product.create_slug! path: old_path
      allow_any_instance_of(Vendor::FilesController).to receive(:aws_object).and_return(double(exists?: false))
    end

    it do
      visit old_path

      expect(page.status_code).to eq 200

      expect(HistoryPath.count).to eq 1
      hp = HistoryPath.last

      expect(hp).to be_present
      expect(hp.path).to eq old_path
      expect(hp.resource).to eq product

      # У товара сменился путь

      product.update slug_attributes: { path: new_path }

      # Идем по старому пути, но нас редиректит на новый
      visit old_path
      expect(page.status_code).to eq 200
      expect(page).to have_current_path new_path, ignore_query: true

      # Еще автоматически создается SlugRedirect чтоы был виден в меню

      slug = SlugRedirect.last
      expect(slug).to be_a(SlugRedirect)
      expect(slug.resource).to eq product
      expect(slug.redirect_path).to eq new_path

      # В истории теперь notfound-ов нет
      hp = HistoryPath.last
      expect(hp.state).to eq 'ok'

      # Если заходить по дефолтному пути, то нас тоже перекидывает на новый
      visit product.default_path
      expect(page.status_code).to eq 200
      expect(page).to have_current_path new_path, ignore_query: true
    end
  end

  describe 'Зацикливающий редирект в никуда' do
    let!(:category)       { create :category, vendor: vendor, title: 'Товары' }
    let!(:child_category) { create :category, vendor: vendor, title: 'Браслеты-нитки' }
    let(:product)         { create :product, vendor: vendor }
    let!(:products)       { vendor.products.page(1).per(20) }

    before do
      Slug.delete_all
      HistoryPath.delete_all
      Capybara.app_host = vendor.home_url
      allow_any_instance_of(Vendor::CategoriesController).to receive(:products).and_return products
    end

    it do
      # Запоминаем slug дочерней категории
      root_level_path = child_category.public_path.dup

      # Делаем категорию некорневой, переносим во вложенную
      child_category.update! parent_id: category.id

      # Запоминаем изменившийся путь у дочерней категории
      nested_level_path = child_category.public_path.dup

      # Если путь не изменился, то это значит что рутовых категории только одна
      if root_level_path == nested_level_path
        expect { vendor.slug_redirects.create!(path: root_level_path, redirect_path: nested_level_path, resource: child_category) }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end
end
