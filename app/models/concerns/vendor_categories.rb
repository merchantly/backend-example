module VendorCategories
  extend ActiveSupport::Concern

  included do
    belongs_to :welcome_category, class_name: 'Category'
    belongs_to :default_import_category, class_name: 'Category'
    belongs_to :package_category, class_name: 'Category'

    if Settings.welcome_category_required
      validates :welcome_category, presence: true, on: :update

      after_create :create_default_welcome_category!
    end
  end

  def get_category(name)
    cat = nil
    if name.present?
      path = name.split('/').map(&:strip)

      path.each do |cat_name|
        cat = Category.find_or_create_by_name self, cat_name, cat
      end
    end

    cat
  end

  def menu_categories
    roots = categories.roots.alive.ordered
    if roots.one?
      roots.take.children.for_auto_menu(self)
    elsif roots.many?
      roots.for_auto_menu self
    else
      # Невозможный набор категорий
      categories.where(id: nil)
    end
  end

  def update_categories_counters!
    CategoryCountersService::UpdateCounters.new(categories: categories.alive).call
  end

  private

  def create_default_welcome_category!
    return if welcome_category.present?

    category = categories.create! custom_title_translations: HstoreTranslate.translations(:default_welcome_category, %i[titles categories])

    update_column :welcome_category_id, category.id
  end

  def welcome_category_belongs_to_vendor
    category_belongs_to_vendor_validation :welcome
  end

  def default_import_category_belongs_to_vendor
    category_belongs_to_vendor_validation :default_import
  end

  def package_category_belongs_to_vendor
    if saved_change_to_package_category_id? && (!package_category_id.nil? && !categories.exists?(id: package_category_id))
      errors.add :package_category_id, I18n.t('activerecord.errors.wrong_category')
    end
  end

  def category_belongs_to_vendor_validation(type)
    if send("#{type}_category_id_changed?") && !categories.exists?(id: send("#{type}_category_id"))
      errors.add "#{type}_category_id".to_sym, I18n.t('activerecord.errors.wrong_category')
    end
  end
end
