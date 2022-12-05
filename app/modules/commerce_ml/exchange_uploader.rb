module CommerceML
  class ExchangeUploader < CarrierWave::Uploader::Base
    storage :file

    def store_dir
      "#{model.class.to_s.underscore}/#{model.id}" # /#{mounted_as}"
    end

    def root
      Rails.root.join('tmp/commerce_ml')
    end

    def filename
      model.filename.presence || original_filename
    end
  end
end
