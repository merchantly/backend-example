# Этот модуль используется во всех моделях импортируемых
# из moysklad. Поэтому тут нет упоминания про consignment, которые
# специфичны только для product/feature

module MoyskladEntity
  NoMsDump = Class.new StandardError
  extend ActiveSupport::Concern

  included do
    scope :by_externalcode,   ->(ec)        { raise 'No external code' unless ec; where externalcode: ec }
    scope :by_ms_uuid,        ->(uuid)      { where ms_uuid: uuid }

    scope :stock_linked, -> { where.not ms_uuid: nil }
    scope :not_linked, -> { where ms_uuid: nil }
    scope :not_synced, lambda { |synced_at|
      where "#{arel_table.name}.stock_synced_at<? or #{arel_table.name}.stock_synced_at is null", synced_at
    }

    scope :by_ms_entity, lambda { |entity|
      if entity.respond_to? :externalCode
        by_externalcode entity.externalCode
      else
        by_ms_uuid entity.id
      end
    }

    validates :ms_uuid,      uniqueness: { scope: :vendor_id }, allow_blank: true
    validates :externalcode, uniqueness: { scope: :vendor_id }, allow_blank: true

    has_one :moysklad_object, as: :reference

    delegate :stock_dump, :consignment_dump, to: :moysklad_object, allow_nil: true

    accepts_nested_attributes_for :moysklad_object
  end

  def update_stock_dump(stock_dump)
    if moysklad_object.present? && moysklad_object.persisted?
      moysklad_object.update_column :stock_dump, stock_dump unless moysklad_object.stock_dump == stock_dump
    else
      create_moysklad_object stock_dump: stock_dump
    end
  end

  def update_consignment_dump(consignment_dump)
    if moysklad_object.present? && moysklad_object.persisted?
      moysklad_object.update_column :consignment_dump, consignment_dump unless moysklad_object.consignment_dump == consignment_dump
    else
      create_moysklad_object consignment_dump: consignment_dump
    end
  end

  def dumped_externalCode
    return if stock_dump.blank?

    @dumped_externalcode ||= Nokogiri.parse(stock_dump).xpath('//externalcode').text
  rescue StandardError => e
    Bugsnag.notify e, metaData: { id: id, type: self.class.name }
    binding.debug_error
    nil
  end

  def dumped_ms_entity
    raise NoMsDump if stock_dump.blank?

    JSON.parse(stock_dump)
  rescue StandardError => e
    Bugsnag.notify e, metaData: { id: id, type: self.class.name }
    raise NoMsDump, e.message
  end

  def linked?
    stock_linked?
  end

  def stock_linked?
    ms_uuid.present?
  end

  def active_stock_linked?
    stock_linked? && vendor.ms_valid? && vendor.is_stock_linked?
  end
end
