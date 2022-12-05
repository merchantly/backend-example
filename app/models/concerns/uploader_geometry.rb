module UploaderGeometry
  NET_TIMEOUT = 2

  def height
    geometry.second
  end

  def width
    geometry.first
  end

  # TODO thumbor
  def geometry
    @geometry ||= ::MiniMagick::Image.open(image_file_or_url, read_timeout: NET_TIMEOUT, open_timeout: NET_TIMEOUT)[:dimensions]
  rescue StandardError => e
    raise e if Rails.env.test?

    Bugsnag.notify e do |b|
      b.meta_data = { model_class: model.try(:class), model_id: model.try(:id), file: image_file_or_url }
    end
    [nil, nil]
  end

  def adjusted_url(width: nil, height: nil, size: nil, filters: [])
    if size.present?
      width = size
      height = size
    end

    params = {}
    params[:width] = width if width.present?
    params[:height] = height if height.present?
    params[:filters] = filters if filters.present?
    thumbor_url params
  end

  def thumbor_url(params = {})
    ThumborService.new(self).url params
  end

  private

  # When file just loaded it is not exists in S3, give it localy
  def image_file_or_url
    if file.present?
      file.respond_to?(:url) ? file.url : file.file
    else
      # No reaseone to returl url (defualt_url) because file uses to reade localy
      File.open(ImageUploader::FALLBACK_IMAGE_PATH)
    end
  end
end
