# Source:
# https://github.com/alfadoblemas/refinerycms-liquid/blob/master/lib/refinery/refined_liquid.rb
#
module Droppable
  def get_drop_class(class_obj)
    raise NoDrop if class_obj.blank?

    begin
      drop_string = "#{class_obj}Drop"
      drop_string.constantize
    rescue NameError
      get_drop_class class_obj.superclass
    end
  end

  def to_liquid
    drop_class = get_drop_class self.class
    drop_class.new self
  rescue NoDrop
    raise NoDrop, self.class
  end

  def collection_label
    return label if respond_to? :label
    return title if respond_to? :title
    return name  if respond_to? :name

    "label for item number :#{id}"
  end

  class NoDrop < StandardError
    def message
      "No drop for #{super}"
    end
  end
end

ActiveRecord::Base.include Droppable
