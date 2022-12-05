class VendorFavicons
  CUSTOM_CSS_FILE_NAME = 'custom.css'.freeze

  include Virtus.model

  attribute :vendor, Vendor

  def save(file)
    if file.is_a? ActionDispatch::Http::UploadedFile
      name = file.original_filename
    else
      name = Pathname.new(file.path).basename.to_s
    end
    raise FaviconFilenameError, name unless FaviconHelper::NAMES.include? name

    aws_client.upload favicon_path(name), file

    update_cache_favicons!
  end

  def get(filename)
    aws_client.object favicon_path(filename)
  end

  def url(filename)
    aws_client.url favicon_path(filename)
  end

  def delete(filename)
    aws_client.delete favicon_path(filename)

    update_cache_favicons!
  end

  private

  def favicon_path(filename)
    "favicons/#{filename}"
  end

  def aws_client
    @aws_client ||= AwsService.new(vendor: vendor)
  end

  def update_cache_favicons!
    vendor.update_columns(
      aws_favicons_cache: fetch_favicons,
      favicons_updated_at: Time.zone.now
    )
  end

  def fetch_favicons
    aws_client.fetch('favicons/')
      .collect { |o| Pathname.new(o.key).basename.to_s }
      .select { |n| FaviconHelper::NAMES.include? n }
      .compact
      .sort
  end

  class FaviconFilenameError < StandardError
    def message
      I18n.t('errors.favicon_uploader.filename', name: super)
    end
  end
end
