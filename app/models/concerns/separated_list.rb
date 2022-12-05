module SeparatedList
  def parse_separated_list(text)
    text.to_s.split("\n").map do |p|
      p.squish!
      if p.present?
        block_given? ? yield(p) : p
      else
        nil
      end
    end.compact
  end
end
