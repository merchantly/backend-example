# выдает следующий по сортировке ресурс
# либо тот который прикреплен как следующий
module NextResourceConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :next_resource, class_name: name
  end

  def next_ordered_resource
    next_resource || self.class.alive.has_any_published_goods.ordered.find_by('position > ? AND vendor_id = ?', position, vendor_id)
  end
end
