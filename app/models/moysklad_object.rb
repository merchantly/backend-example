class MoyskladObject < ApplicationRecord
  belongs_to :reference, polymorphic: true
end
