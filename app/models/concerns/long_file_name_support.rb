# Автоматически обрезаем длинные имена, чтобы не попадать на Errno::ENAMETOOLONG
# Источник: https://github.com/carrierwaveuploader/carrierwave/pull/539
module LongFileNameSupport
  # 255 characters is the max size of a filename in modern filesystems
  # and 150 characters are allocated for versions
  MAX_FILENAME_LENGTH = 255 - 150

  def original_filename
    value = super
    return unless value

    filename = File.basename value

    if filename.size > MAX_FILENAME_LENGTH
      extension = if filename =~ /\./
                    filename.split(/\./).last
                  else
                    false
                  end

      # 32 for MD5 and 2 for the __ separator
      split_position = MAX_FILENAME_LENGTH - 32 - 2
      # +1 for the . in the extension
      if extension
        split_position -= (extension.size + 1)
      end

      hex = Digest::MD5.hexdigest(filename[split_position, filename.size])

      filename = "#{filename[0, split_position]}__#{hex}"
      filename << (".#{extension}") if extension
    end

    filename
  end
end
