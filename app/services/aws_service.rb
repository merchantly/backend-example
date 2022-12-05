class AwsService
  include Virtus.model

  attribute :vendor, Vendor

  CACHE_CONTROL = 'public, max-age=600'.freeze
  ACL = 'public-read'.freeze
  AWS_ROOT_PATH = 'uploads/shop/'.freeze

  def upload(key, body)
    raise "key '#{key}' must not start with slash" if key.start_with? '/'

    S3Bucket.put_object(
      key: aws_root_path + key,
      cache_control: AwsService::CACHE_CONTROL,
      acl: AwsService::ACL,
      body: body,
      content_type: MimeMagic.by_path(key).type
    )
  end

  def object(filename)
    S3Bucket.object path(filename)
  end

  def url(filename)
    url_by_key object(filename).key
  end

  def url_by_key(key)
    "#{Settings.aws_proxy_url}/#{key}"
  end

  def path(filename)
    aws_root_path + filename
  end

  def delete(filename)
    object(filename).delete
  end

  def fetch(prefix)
    S3Bucket.objects(prefix: (aws_root_path + prefix), max_keys: 20)
  end

  def copy(from, to)
    object(from).copy_to [Secrets.aws.bucket, path(to)].join('/'), acl: ACL
  end

  private

  def aws_root_path
    "#{AWS_ROOT_PATH}#{vendor.id}/"
  end
end
