class SlugRedirect < Slug
  has_one :redirect_history_path, -> { not_founds }, foreign_key: :path, primary_key: :redirect_path, class_name: 'HistoryPath'

  before_validation :fix_redirect_path
  validates :redirect_path, presence: true
  validate :paths_not_equal
  validate :validate_path

  before_save :attach_resource

  after_commit on: :create do
    history_path.try :destroy
  end

  def vendor_controller
    'vendor/slug_redirect'
  end

  def alive?
    resource.try(:public_path) == redirect_path
  end

  def redirect_url
    if redirect_path_absolute?
      redirect_path
    else
      vendor.home_url + redirect_path
    end
  end

  private

  def paths_not_equal
    errors.add :redirect_path, I18n.t('errors.slug_redirect.path_equals_to_redirect') if redirect_path == path
  end

  def attach_resource
    if resource.blank?
      found_resource = vendor.slug_resources.find_by(path: redirect_path).try :resource
      self.resource = found_resource if found_resource.present?
    end
  end

  def fix_redirect_path
    self.redirect_path = fix_path redirect_path unless redirect_path_absolute?
  end

  def redirect_path_absolute?
    redirect_path.start_with? 'http'
  end

  def validate_path
    errors.add :path, I18n.t('errors.slug_redirect.operator_path') if path.start_with? '/operator'
  end
end
