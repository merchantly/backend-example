class ApplicationRecord < ActiveRecord::Base
  acts_as_copy_target

  MAX_INTEGER = 2_147_483_647

  self.abstract_class = true
end
