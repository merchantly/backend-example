class AbstractBaseSpreadsheet
  attr_reader :collection

  def initialize(collection)
    @collection = collection
  end

  def to_csv
    converter = lambda do |s|
      return s unless s.is_a? String

      encoding.present? ? s.encode(encoding, invalid: :replace, undef: :replace) : s
    end
    # options = { col_sep: ';' }
    CSV.generate do |csv|
      csv << header_row.map(&converter)
      collection.find_in_batches do |batch|
        batch.each do |item|
          csv << row(item).map(&converter)
        end
      end
    end
  end

  private

  def encoding
    nil
  end

  def header_row
    'not implemented'
  end

  def row(_item)
    'not implemented'
  end
end
