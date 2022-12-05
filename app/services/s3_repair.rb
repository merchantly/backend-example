# Восстанавливает Cache-Control, acl и удаляет expires
# у всех объектов в S3
#
class S3Repair
  # https://gist.github.com/mattboldt/6052bac987c16b73563d4d6c56d7509b
  # :expires удален
  COPY_TO_OPTIONS = %i[multipart_copy copy_source_client copy_source_region acl cache_control content_disposition content_encoding content_language content_type copy_source_if_match copy_source_if_modified_since copy_source_if_none_match copy_source_if_unmodified_since grant_full_control grant_read grant_read_acp grant_write_acp metadata metadata_directive tagging_directive server_side_encryption storage_class website_redirect_location sse_customer_algorithm sse_customer_key sse_customer_key_md5 ssekms_key_id copy_source_sse_customer_algorithm copy_source_sse_customer_key copy_source_sse_customer_key_md5 request_payer tagging use_accelerate_endpoint].freeze

  def initialize
    @invalids = []
    @invalid_file = File.open Rails.root.join('./tmp/invalid_s3_keys.txt'), 'w'
  end

  def perform
    S3Bucket.objects.each_with_index do |object_summary, index|
      perform_object object_summary, index
    end
  ensure
    invalid_file.close
  end

  private

  attr_reader :invalids, :invalid_file

  InvalidFile = Class.new StandardError

  def total
    @total ||= S3Bucket.objects.count
  end

  # object <Aws::S3::ObjectSummary>
  #
  def perform_object(object_summary, index)
    key = object_summary.key
    object = object_summary.object

    if key.end_with?('.css', 'robots.txt')
      cache_control = AwsService::CACHE_CONTROL

    elsif key =~ /\/sitemaps\//
      cache_control = 'private, max-age=0, no-cache'

    elsif key =~ /\/favicons\//
      cache_control = VendorLogoUploader::CACHE_CONTROL

    else
      cache_control = CarrierWave::Uploader::Base.aws_attributes[:cache_control]

      validate_file_ownership key

    end

    data = object.data

    if data.cache_control == cache_control && data.expires.nil?
      puts "[#{index}/#{total}] #{key}: OK"
    else
      puts "[#{index}/#{total}] #{key}: new=#{cache_control}, was=#{data.cache_control}"

      options = data.to_h.slice(*COPY_TO_OPTIONS).merge(
        acl: 'public-read',
        cache_control: cache_control,
        metadata_directive: 'REPLACE'
      )
      object.copy_to object, options
    end
  end

  MODEL_CLASSES = [Category, AssetImage, VendorTheme, VendorJob, ContentPageImage, DictionaryColor, Dictionary, LookbookImage, BlogPost, SliderImage, ProductImage, DictionaryEntity]
    .index_by { |model_class| model_class.to_s.underscore }

  # "uploads/shop/#{model.vendor_id}/images" AssetImage
  # "uploads/shop/#{model.vendor_id}/uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  # "uploads/shop/#{model.vendor_id}/uploads/af/#{model.property_id}"
  # uploads/shop/1024/uploads/lookbook_image/image/498/e7f83e92-eb4e-4443-8add-de7c643ff8ee.jpg
  # uploads/shop/1024/uploads/blog_post/image/217/c0b4843f-2dee-473e-a36c-d0703e52d3d7.jpg
  # uploads/shop/1019/uploads/slider_image/image/729/4d289d0f-415f-4949-980b-653fbf5d7038.jpg
  # uploads/shop/101/uploads/product_image/image/26512/d5e86a65-73ca-4d77-98ec-1e44d5a7141d.jpg
  def validate_file_ownership(key)
    # TODO проверять favicons
    return if key.start_with? 'uploads/system'

    case key
    when /^uploads\/shop\/(\d+)\/uploads\/([a-z_]+)\/([a-z_]+)\/(\d+)\/(.+)$/
      vendor_id = Regexp.last_match(1)
      model = Regexp.last_match(2)
      mounted_as = Regexp.last_match(3)
      model_id = Regexp.last_match(4)
      filename = Regexp.last_match(5)
      validate_classic_file vendor_id, model, mounted_as, model_id, filename

    when /^uploads\/shop\/(\d+)\/images\/(.+)$/
      vendor_id = Regexp.last_match(1)
      filename = Regexp.last_match(2)
      validate_asset_file vendor_id, filename

    else
      raise InvalidFile, 'Не известный тип файла'
    end
  rescue InvalidFile => e
    add_invalid key, e
  rescue StandardError => e
    puts "UNKNOWN ERROR #{key}: #{e}"
    add_invalid key, e
  end

  def validate_asset_file(vendor_id, filename)
    vendor = Vendor.find_by(id: vendor_id) || raise(InvalidFile, "Не найден магазин #{vendor_id}")
    raise InvalidFile, "Не найден AssetImage #{filename} в магазине #{vendor_id}" unless vendor.asset_images.exists?(image: filename)
  end

  def validate_classic_file(vendor_id, model, mounted_as, model_id, filename)
    vendor = Vendor.find_by(id: vendor_id) || raise(InvalidFile, "Не найден магазин #{vendor_id}")

    model_class = MODEL_CLASSES[model] || raise(InvalidFile, "Не найден ресурс #{model}")

    record = model_class.find_by(id: model_id) || raise(InvalidFile, "Не найдена запись #{model_class}[#{model_id}]")
    raise InvalidFile, "У модели другой вендор #{record.vendor_id}<>#{vendor.id}" unless record.vendor_id == vendor.id

    mountes = model_class.uploaders.keys.map(&:to_s)
    raise InvalidFile, "Не существует такого uploader-а #{mounted_as} в модели #{model_class}" unless mountes.include? mounted_as

    value = record.read_attribute mounted_as

    raise InvalidFile, "filename отличается #{value}<>#{filename} в модели #{model_class}[#{model_id}]##{mounted_as}" unless value == filename

    true
  end

  def add_invalid(key, err)
    buffer = "#{key}\t#{err.class}\t#{err.message}\n"
    puts "InvalidFile: #{buffer}"

    invalids.push key: key, error: err
    invalid_file.write buffer
    invalid_file.flush
  end
end
