class BranchCategory < ApplicationRecord
  has_many :vendors, dependent: :restrict_with_exception

  scope :by_group, ->(group) { where CategoryGroup: group }

  validates :CategoryId, presence: true
  validates :CategoryGroup, presence: true
  validates :title, presence: true, uniqueness: { scope: %i[CategoryId CategoryGroup] }

  def self.groups
    BranchCategory.group(:CategoryGroup).pluck(:CategoryGroup).map do |name|
      BranchCategory::Group.new key: name
    end
  end

  def to_s
    title
  end
end

class BranchCategory::Group
  include Virtus.model
  attribute :key, String

  def title
    I18n.t key, scope: :branch_categories
  end

  def to_s
    title
  end

  def categories
    @categories ||= BranchCategory.by_group key
  end
end
