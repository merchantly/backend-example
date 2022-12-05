module ClientScopes
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model

    scope :by_phone, ->(phone) { joins(:phones).where client_phones: { phone: Phoner::Phone.parse(phone).to_s } }
    scope :by_email, ->(email) { joins(:emails).where client_emails: { email: email.to_s.downcase } }

    scope :by_phone_or_email, lambda { |phone, email|
      if phone.present? && email.present?
        joins(:phones, :emails)
          .where('client_phones.phone = ? or client_emails.email = ?',
                 Phoner::Phone.parse(phone).to_s,
                 email.to_s.downcase)
      elsif phone.present?
        joins(:phones).where(client_phones: { phone: Phoner::Phone.parse(phone).to_s })
      elsif email.present?
        joins(:emails).where(client_emails: { email: email.to_s.downcase })
      else
        none
      end
    }

    scope :by_query, ->(query) { joins(:phones, :emails).where("client_phones.phone = ? OR client_emails.email = ? OR #{table_name}.name ILIKE ?", query, query, "%#{query}%") }
    scope :ordered, -> { order orders_count: :desc }

    scope :auth_by_phone,    ->(login, password) { joins(:phones).where('client_phones.phone = ? AND (clients.password = ? OR clients.pin_code = ? )', login, password, password) }
    scope :auth_by_email,    ->(login, password) { joins(:emails).where(password: password, client_emails: { email: login }) }

    scope :by_scope, ->(scope) { where moderation_state: scope }

    pg_search_scope :by_address,
                    against: %i[address],
                    using: {
                      tsearch: { dictionary: 'russian' }
                    }

    pg_search_scope :by_name,
                    against: %i[name],
                    using: {
                      tsearch: { dictionary: 'russian' },
                      trigram: { only: :name }
                    }

    pg_search_scope :by_search_email,
                    associated_against: {
                      emails: [:email]
                    },
                    using: [:trigram]

    pg_search_scope :by_search_phone,
                    associated_against: {
                      phones: [:phone]
                    },
                    using: [:trigram]
  end
end
