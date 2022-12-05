module FixPath
  def fix_path(path)
    return path if path.blank?

    path = "/#{path}" unless path.start_with? '/'

    path = path.slice 0, path.length - 1 if path.length > 1 && path.end_with?('/')

    path
  end
end
