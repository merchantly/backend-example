class TopBanner < ApplicationRecord
  include Authority::Abilities

  belongs_to :vendor

  validates :link_url, allow_blank: true, length: { maximum: 2000 } # , url: true

  translates :content
end
