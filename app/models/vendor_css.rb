class VendorCss
  include AutoLogger

  CUSTOM_CSS_FILE_NAME = 'custom.css'.freeze

  include Virtus.model

  attribute :vendor, Vendor

  def archive(operator)
    archived_css = ArchivedCss.build_by_operator(operator)

    aws_client.copy CUSTOM_CSS_FILE_NAME, archived_css.name
  rescue Aws::S3::Errors::NoSuchKey => e
    logger.info e
  end

  def archived
    aws_client.fetch(ArchivedCss::PREFIX).map do |object|
      ArchivedCss.build_from_url aws_client.url_by_key(object.key)
    end.reverse
  end

  def save(content)
    aws_client.upload CUSTOM_CSS_FILE_NAME, content
  end

  def get
    aws_client.object CUSTOM_CSS_FILE_NAME
  end

  def url
    aws_client.url CUSTOM_CSS_FILE_NAME
  end

  private

  def aws_client
    @aws_client ||= AwsService.new(vendor: vendor)
  end
end
