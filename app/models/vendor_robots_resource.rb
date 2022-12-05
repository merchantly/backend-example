class VendorRobotsResource
  ROBOTS_FILE_NAME = 'robots.txt'.freeze

  include Virtus.model

  attribute :vendor, Vendor

  def save(content)
    return if Rails.env.test?

    Rails.logger.debug { "AWS upload robots content: #{content}" }
    aws_client.upload ROBOTS_FILE_NAME, content
  end

  def get
    return 'test stub' if Rails.env.test?

    aws_client.object(ROBOTS_FILE_NAME).get.body.read
  rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::AccessDenied => e
    Rails.logger.error "vendor_id=#{vendor.id} #{e}"
    ''
  end

  private

  def aws_client
    @aws_client ||= AwsService.new(vendor: vendor)
  end
end
