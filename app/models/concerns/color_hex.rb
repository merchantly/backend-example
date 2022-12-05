module ColorHex
  extend ActiveSupport::Concern

  DEFAULT_COLOR_HEX = '#eee'.freeze

  def opposite_color
    if color.brightness > 0.8
      Color::RGB.by_hex '#000'
    else
      Color::RGB.by_hex '#fff'
    end
  end

  def text_style
    return '' if color.blank?

    "color: #{color.css_rgb}"
  end

  def label_style
    return '' if color.blank?

    "color: #{color.css_rgb}; border-color: #{color.css_rgb}"
  end

  def bg_style
    return '' if color.blank?

    "background-color: #{color.css_rgb}; border: none; color: #{opposite_color.css_rgb}"
  end

  def border_style
    return '' if color.blank?

    "border-color: #{color.css_rgb}"
  end

  def color
    Color::RGB.by_hex(color_hex.presence || DEFAULT_COLOR_HEX)
  rescue ArgumentError
    nil
  end
end
