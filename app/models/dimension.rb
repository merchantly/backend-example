class Dimension
  include Virtus.model

  attribute :height, Integer, default: 0
  attribute :length, Integer, default: 0
  attribute :width, Integer, default: 0
end
