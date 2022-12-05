class Tasty::ProductParamsBuilder < ApplicationController
  include Virtus.model

  UTM_SOURCE = 'taaasty'.freeze
  UTM_MEDIUM = 'potok'.freeze
  UTM_CAMPAIGN = 'shop'.freeze

  attribute :product, Product
  attribute :tasty_tlog_id, String

  def as_json
    {
      title: title,
      image_url: image_url,
      tlog_id: tasty_tlog_id,
      privacy: privacy
    }
  end

  private

  def title
    render_to_string 'tasty/product', locals: { url: url, product: product }
  end

  def url
    "#{product.public_url}?utm_source=#{UTM_SOURCE}&utm_medium=#{UTM_MEDIUM}&utm_campaign=#{UTM_CAMPAIGN}"
  end

  def image_url
    product.mandatory_index_image.image_url
  end

  def privacy
    'public_with_voting'
  end
end
