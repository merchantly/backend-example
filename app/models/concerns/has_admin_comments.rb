module HasAdminComments
  extend ActiveSupport::Concern

  included do
    has_many :admin_comments,
             -> { order id: :desc },
             as: :resource,
             class_name: 'ActiveAdmin::Comment',
             dependent: :delete_all
  end
end
