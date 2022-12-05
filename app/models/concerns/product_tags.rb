module ProductTags
  extend ActiveSupport::Concern
  DELIMITER = ','.freeze

  included do
    has_many :product_tags, dependent: :destroy
    has_many :tags, through: :product_tags

    accepts_nested_attributes_for :tags

    after_save :save_tags_list
  end

  def tags_list(force = false)
    @tags_list = nil if force
    @tags_list ||= tags.map(&:title).join DELIMITER
  end

  def tags_list=(list)
    @tags_list_changed = true
    @tags_list = clean_tags_list list

    save_tags_list if persisted?
    @tags_list
  end

  def add_tag(title)
    tag = vendor.tags.by_title(title).take || vendor.tags.create_by_title!(title)
    tags << tag
  end

  private

  def save_tags_list
    return unless @tags_list_changed

    self.tags = @tags_list.split(DELIMITER).map { |title| vendor.tags.by_title(title).take || vendor.tags.create_by_title!(title) }
  end

  def clean_tags_list(list)
    list.split(DELIMITER).map(&:squish).join(DELIMITER)
  end
end
