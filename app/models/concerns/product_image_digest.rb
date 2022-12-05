require 'digest'

module ProductImageDigest
  extend ActiveSupport::Concern

  included do
    before_create :build_digest
  end

  private

  def build_digest
    case image.file
    when CarrierWave::SanitizedFile
      self.digest = Digest::SHA256.file(image.file.file).hexdigest
    when CarrierWave::Storage::AWSFile
      self.digest = image.file.file.etag
    else
      raise "Не известный тип #{image.file.class}"
    end
  end
end
