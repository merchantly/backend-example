class RolePermission < ApplicationRecord
  extend Enumerize

  Dir['app/authorizers/**/*.rb'].each { |f| require_dependency("#{Dir.pwd}/#{f}") }
  EXCLUDE_AUTHORIZERS_LIST = [VendorResourceAuthorizer].freeze
  AUTHORIZERS_LIST = ApplicationAuthorizer.descendants - EXCLUDE_AUTHORIZERS_LIST
  RESOURCE_TYPES_LIST = AUTHORIZERS_LIST.map { |r| r.model_class.to_s }.uniq

  belongs_to :role

  validates :resource_type, presence: true
  validates :resource_type, uniqueness: { scope: [:role_id] }

  validate :validate_can_presence

  scope :ordered, -> { order :title }
  scope :by_resource_type, ->(class_name) { find_by(resource_type: class_name) }

  enumerize :resource_type, in: RESOURCE_TYPES_LIST

  private

  def validate_can_presence
    return if can_read || can_create || can_update || can_delete

    %i[can_read can_update can_create can_delete].each do |can|
      errors.add can, 'None of the accesses are specified '
    end
  end
end
