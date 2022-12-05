class VendorTemplate < ApplicationRecord
  include Archivable
  include Sortable
  IMAGE_WIDTH = 600
  IMAGE_HEIGHT = 600

  mount_uploader :image, SystemUploader

  belongs_to :vendor, counter_cache: :templates_count
  has_many :vendors, dependent: :nullify
  has_many :precreated_vendors, -> { pre_created }, class_name: 'Vendor'
  has_many :real_vendors, -> { not_pre_created }, class_name: 'Vendor'

  scope :tests, -> { where is_test: true }
  scope :published, lambda { |is_super_admin = false|
    if is_super_admin
      alive.ordered
    else
      alive.where(is_test: false).ordered
    end
  }

  ranks :position

  validates :name, :description, presence: true
  validates :image, geometry: { width: IMAGE_WIDTH, height: IMAGE_HEIGHT }, presence: true

  validate do
    if vendor.present?
      errors.add :vendor_id, 'Магазин для шаблона должен быть пустышкой, без операторов' if vendor.owners.any?
      errors.add :vendor_id, 'Магазин не должен иметь флага is_pre_created' if vendor.is_pre_create?
    end
  end

  delegate :count, to: :precreated_vendors, prefix: true
  delegate :count, to: :vendors, prefix: true
  delegate :count, to: :real_vendors, prefix: true

  def to_s
    name
  end

  def self.default
    alive.ordered.first
  end

  def next_precreated_vendor
    precreated_vendors.first
  end

  def next_precreated_vendor!
    next_precreated_vendor || precreate!
  end

  def precreate!(name: nil)
    VendorCloneWorker.new.direct_perform vendor_template: self, from_vendor: vendor, name: name
  end
end
