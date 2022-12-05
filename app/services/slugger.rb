module Slugger
  def self.slug_postfix(title)
    buffer = title.truncate(150).html_safe rescue nil
    str = Russian.transliterate(buffer).truncate(80).parameterize
    str.presence
  rescue StandardError
    nil
  end
end
