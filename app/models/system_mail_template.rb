# шаблоны для новостных/технических рассылок
class SystemMailTemplate < ApplicationRecord
  extend Enumerize
  include Archivable
  include ::SystemMailTemplateContextExample

  has_many :system_mail_deliveries

  belongs_to :example_vendor, class_name: 'Vendor'
  belongs_to :example_operator, class_name: 'Operator'

  # Новости, анонсы, маркетинговая информация
  TYPE_NEWS = 'news'.freeze
  # Редкие письма о технических работах и изменении в тарифах и важная информация
  TYPE_TECH = 'tech'.freeze
  # Аналитика, рассылается раз в неделю
  TYPE_ANALYTICS = 'analytics'.freeze

  TYPES = [TYPE_TECH, TYPE_NEWS, TYPE_ANALYTICS].freeze

  validates :title, presence: true
  validates :content, liquid: true
  validates :subject, liquid: true
  validates :template_type, presence: true

  mount_uploader :image, SystemUploader

  enumerize :template_type, in: TYPES

  before_destroy do
    system_mail_deliveries.previews.destroy_all
  end

  before_save do
    self.title = subject if title.blank?
  end

  def title
    subject
  end
end
