module SecuryFilename
  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end
end
