require 'rails_helper'

describe ImportFromSpreadsheet do
  INDEX_NAME     = 0
  INDEX_ARTICLE  = 1
  INDEX_PRICE    = 2
  INDEX_CATEGORY = 4
  INDEX_QUANTITY = 5
  EXIST_PRODUCT_ARTICLE = '428131-0'.freeze

  let(:vendor) { create :vendor }
  let!(:exist_product) { create :product, :archived, vendor: vendor, article: EXIST_PRODUCT_ARTICLE }

  let(:import_spread_sheet_info) { create :import_spread_sheet_info, vendor: vendor, locale: 'ru' }

  before do
    stub_google_spreadsheet(rows)
  end

  describe 'all products valid' do
    let(:rows) do
      [
        [
          'Наименование', 'Артикул', 'Цена',
          'Цена распродажи', 'Категория', 'Количество',
          'Описание', 'Стиль', 'Размер',
          'Вставка', 'Проба', 'Вес', 'Покрытие'
        ],
        [
          'Браслет Клубничка', EXIST_PRODUCT_ARTICLE, '2 160,00',
          '2 000,00', 'Браслет', '1',
          '', 'Для маленких принцесс', '14',
          'эмаль', '925', '3,21', 'родий'
        ],
        [
          'Браслет Рыбка', '428131-1', '1910',
          '1 000,00', 'Браслет', '1',
          '', 'Для маленких принцесс', '14',
          'камень', '930', '4,21', 'золото'
        ],
        [
          'Браслет Пингвинчик', '428131-2', '2 050,00',
          '', 'Браслет2', '2',
          'описание', 'Для маленких принцесс', '17',
          'эмаль', '940', '5', 'серебро'
        ],
      ]
    end

    it 'counts' do
      import_spread_sheet_info.import!

      expect(vendor.products.count).to eq 3
      expect(vendor.categories.count).to eq(Settings.welcome_category_required ? 3 : 2)
      expect(vendor.properties.count).to eq 6
      expect(vendor.import_spread_sheet_infos.last.result_messages.count).to eq 0
    end

    it 'product unarchived' do
      expect(exist_product).to be_archived
      import_spread_sheet_info.import!
      expect(exist_product.reload).not_to be_archived
    end

    it 'properties' do
      import_spread_sheet_info.import!

      (1..3).each do |row_index|
        product = vendor.products.by_title(import_spread_sheet_info.rows[row_index][INDEX_NAME]).first
        # категории
        expect(product.categories.map(&:title)).to include import_spread_sheet_info.rows[row_index][INDEX_CATEGORY]

        # Цены
        expect(product.price).to eq import_spread_sheet_info.rows[row_index][INDEX_PRICE].to_money

        # Артикул
        expect(product.article).to eq import_spread_sheet_info.rows[row_index][INDEX_ARTICLE]

        # Кол-во
        expect(product.quantity).to eq import_spread_sheet_info.rows[row_index][INDEX_QUANTITY].to_i
      end

      # свойства
      # проверяем что бы каждому свойству соответствовал верный набор values
      (7..12).each do |col_index|
        values = import_spread_sheet_info.rows[1..import_spread_sheet_info.rows.count].map { |row| row[col_index] }.uniq.sort
        property_name = import_spread_sheet_info.rows[0][col_index]
        property_key = "property:#{property_name.parameterize}"
        expect(vendor.properties.by_key(property_key).first.values.sort).to eq values
      end
    end
  end

  describe 'not all products valid' do
    let(:rows) do
      [
        [
          'Наименование', 'Артикул', 'Цена',
          'Цена распродажи', 'Категория', 'Количество',
          'Описание', 'Стиль', 'Размер',
          'Вставка', 'Проба', 'Вес', 'Покрытие'
        ],
        [
          '', '', '2 160,00',
          '2 000,00', 'Браслет', '1',
          '', 'Для маленких принцесс', '14',
          'эмаль', '925', '3,21', 'родий'
        ]
      ]
    end

    it do
      import_spread_sheet_info.import!
      expect(vendor.import_spread_sheet_infos.last.result_messages.count).to eq 1
    end
  end
end
