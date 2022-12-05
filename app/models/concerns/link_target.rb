module LinkTarget
  extend ActiveSupport::Concern

  VALUES = %w[_blank _self].freeze

  included do
    validates :link_target, inclusion: { in: VALUES }
  end
end
