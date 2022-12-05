module CSE
  module Entities
    class CSEDocument < Virtus::Attribute
      def coerce(value)
        value.is_a?(::Array) ? value.map { |v| CSE::Entities::Document.new(v) } : value
      end
    end

    class CSEHistoryItem < Virtus::Attribute
      def coerce(value)
        value.is_a?(::Array) ? value.map { |v| CSE::Entities::HistoryItem.new(v) } : value
      end
    end

    class HistoryItem
      include Virtus::Model

      attribute :event_date_time
      attribute :event_date_time_iso, DateTime
      attribute :event_state
      attribute :event_state_code
      attribute :event_name
      attribute :event_comment
    end

    class Document
      include Virtus::Model

      attribute :number
      attribute :client_number
      attribute :name
      attribute :packages
      attribute :deletion_mark, Boolean
      attribute :last_event_date_time
      attribute :last_event_date_time_iso, DateTime
      attribute :last_event_state, String
      attribute :last_event_stateCode
      attribute :last_event_name
      attribute :last_event_comment
      attribute :delivery_date_time
      attribute :delivery_date_time_iso, DateTime
      attribute :recipient
      attribute :history, CSEHistoryItem
      attribute :error, Boolean
      attribute :error_info
    end

    class Response
      include Virtus::Model

      attribute :documents, CSEDocument
      attribute :error, Boolean
      attribute :error_info

      def self.build_from_body(body)
        new ::MultiJson.load(body).underscore_keys
      end
    end
  end
end
