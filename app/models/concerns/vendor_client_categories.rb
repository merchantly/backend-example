module VendorClientCategories
  extend ActiveSupport::Concern

  included do
    has_many :client_categories, dependent: :destroy

    belongs_to :anonymous_client_category, class_name: 'ClientCategory'
    belongs_to :default_client_category, class_name: 'ClientCategory'
    after_create :create_client_categories
  end

  private

  def create_client_categories
    anonymous = client_categories.create! title_translations: HstoreTranslate.translations(:anonymous, %i[titles client_categories])
    default = client_categories.create! title_translations: HstoreTranslate.translations(:registered, %i[titles client_categories])

    update_columns anonymous_client_category_id: anonymous.id, default_client_category_id: default.id
  end
end
