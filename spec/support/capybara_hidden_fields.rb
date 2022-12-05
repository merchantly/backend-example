module CapybaraHiddenFields
  # К сожалению hidden_field установить только так
  def fill_in_hidden(name, value)
    first("input[name='#{name}']", visible: false).set value
  end
end
