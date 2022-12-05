module ProductLabelNew
  def is_label_new
    if is_a? ProductUnion
      goods.select(&:is_new).any? || is_new
    else
      is_new
    end
  end
end
