module VendorClient
  extend ActiveSupport::Concern

  included do
    has_many :client_occupations

    accepts_nested_attributes_for :client_occupations, reject_if: :all_blank, allow_destroy: true

    enumerize :client_occupation_validation, in: %i[no_presence presence required]
    enumerize :client_company_name_validation, in: %i[no_presence presence required]
    enumerize :client_authorization_type, in: %i[by_email_or_phone by_phone by_email], default: :by_email_or_phone
  end

  def client_occupation_present?
    %i[presence required].include? client_occupation_validation.to_sym
  end

  def client_company_name_present?
    %i[presence required].include? client_company_name_validation.to_sym
  end

  def allow_client_auth_by_phone?
    %i[by_phone by_email_or_phone].include? client_authorization_type.to_sym
  end

  def allow_client_auth_by_email?
    %i[by_email by_email_or_phone].include? client_authorization_type.to_sym
  end
end
