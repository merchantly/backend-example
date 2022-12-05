class CouponImage < ApplicationRecord
  include Authority::Abilities
  extend Enumerize

  DEFAULT_ATTRS = {
    x: 140,
    y: 130,
    font_size: 40,
    font_color: 'black',
    align: :center
  }.freeze

  LETTER_SIZE = 0.75

  belongs_to :vendor

  has_many :products

  validates :image, :x, :y, :font_size, presence: true

  enumerize :align, in: %w[none center right left], default: 'none'

  mount_uploader :image, CouponImageUploader

  def result_image_url(str)
    params = [str, calculated_x(str).to_i, y, CGI.escape(font_color), font_size, font].join(',')

    ThumborService.url(image_url: image.url, filters: ["text(#{params})"])
  end

  def calculated_x(str)
    case align.to_sym
    when :right
      text_length = str.length * font_size * LETTER_SIZE
      image.width - text_length
    when :center
      text_length = str.length * font_size * LETTER_SIZE
      center = image.width / 2
      center - (text_length / 2)
    when :left
      LETTER_SIZE
    when :none
      x
    else
      raise "Unknown align #{align}"
    end
  end

  def self.default
    CouponImage.new(DEFAULT_ATTRS).freeze
  end
end
