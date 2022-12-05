module VendorVats
  extend ActiveSupport::Concern

  included do
    validate :validate_vats

    # TODO Спорный момент - нужно ли это делать?
    # before_save :remove_vats_relations, if: :vats_changed?
  end

  def vats_list
    vats.sort.map { |v| Integer(v) == v ? v.to_i : v.to_f }.join(', ')
  end

  def vats_list=(value)
    self.vats = value.split(/[,;]/).map(&:to_f).compact.uniq.sort
  end

  private

  def remove_vats_relations
    nomenclatures.where.not(vat: vats).update_all vat: nil

    product_vat_groups.where.not(vat: vats, id: default_product_vat_group_id).destroy_all
  end

  def validate_vats
    negative_vats = vats.select { |v| v.negative? }
    errors.add :vats_list, I18n.t('errors.negative_vats', examples: negative_vats.join(', ')) if negative_vats.any?
  end
end
