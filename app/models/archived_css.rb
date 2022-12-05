class ArchivedCss
  include Virtus.model

  SEPARATOR = '-'.freeze

  PREFIX = "#{VendorCss::CUSTOM_CSS_FILE_NAME}#{SEPARATOR}".freeze

  attribute :name, String
  attribute :operator, Operator
  attribute :created_at, Time
  attribute :url, String

  def self.build_from_url(url)
    archived_css_name = url.split('/').last

    _css_name, time, operator_id = archived_css_name.split(SEPARATOR)

    new(
      name: archived_css_name,
      created_at: Time.zone.parse(time),
      operator: Operator.find(operator_id),
      url: url
    )
  end

  def self.build_by_operator(operator)
    created_at = Time.zone.now

    new(
      operator: operator,
      created_at: created_at,
      name: [VendorCss::CUSTOM_CSS_FILE_NAME, created_at.to_formatted_s(:number), operator.id].compact.join(SEPARATOR)
    )
  end
end
