module VendorOperatorWarnings
  extend ActiveSupport::Concern

  def add_operator_warning!(key:, type:, message:, expired_at:)
    current_warnings = available_operator_warnings

    exist_warning = current_warnings.find { |cw| cw[:key].to_sym == key }

    if exist_warning.present?
      exist_warning[:type] = type
      exist_warning[:message] = message
      exist_warning[:expired_at] = expired_at
    else
      current_warnings << { key: key, type: type, message: message, expired_at: expired_at }
    end

    update_column :operator_warnings, current_warnings
  end

  def remove_operator_warning(key:)
    current_warnings = available_operator_warnings

    current_warning = current_warnings.find { |cw| cw[:key].to_sym == key }

    return if current_warning.blank?

    current_warnings.delete(current_warning)

    update_column :operator_warnings, current_warnings
  end

  def available_operator_warnings
    operator_warnings.map(&:symbolize_keys).select { |ow| ow[:expired_at] > Time.zone.now }
  end

  def show_operator_warnings
    available_operator_warnings.to_h { |w| [w[:type].to_sym, w[:message]] }
  end
end
