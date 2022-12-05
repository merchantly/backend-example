class SlugResource < Slug
  # При добавлении ресурса:
  # 1. Добавить include Sluggable, методы title и default_path в модель
  # 2. Добавить include SluggableResource и resource в контроллер вендора
  # 3. Добавить slug_attributes: [:id, :path] в permitted_attributes в операторском контроллере
  # 4. Добавить render 'seo_block' в форме редактирования
  #
  RESOURCES = %w[Product Category Dictionary DictionaryEntity ContentPage Lookbook BlogPost].freeze

  before_validation :define_vendor
  before_validation :generate_path, unless: :path, if: :resource

  validates :resource, presence: true
  validates :resource_type, inclusion: RESOURCES, if: :resource_type

  after_create :create_default_history_path

  after_save :link_resources

  def title
    resource.try(:title) || fallback_title
  end

  def vendor_controller
    "vendor/#{resource_type.underscore.pluralize}"
  end

  def operator_resource_path
    "/operator/#{resource_type.underscore.pluralize}/#{resource_id}"
  end

  private

  def link_resources
    vendor.slug_redirects.where(redirect_path: path).update_all resource_type: resource.class.name, resource_id: resource.id
    vendor.history_paths.where(path: path).update_all resource_type: resource_type, resource_id: resource.id
  end

  def define_vendor
    self.vendor_id ||= resource.try :vendor_id
  end

  def fallback_title
    "#{resource_type}##{resource_id}"
  end

  def generate_path
    # TODO Уникальный?
    self.path = resource.title_slug
  end

  def create_default_history_path
    return if vendor.history_paths.by_path(path).exists?

    HistoryPath.transaction requires_new: true do
      vendor.history_paths.create!(
        path: path,
        state: 'slugged',
        resource: resource,
        referer: 'auto',
        controller_name: 'vendor/products',
        action_name: 'show'
      )
    end
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.error "Auto history path is not unuque #{e}"
  end
end
