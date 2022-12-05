module GoogleSpreadsheetMock
  def stub_google_spreadsheet(rows)
    worksheet = double

    allow(worksheet).to receive(:rows).and_return rows
    allow(worksheet).to receive(:num_rows).and_return rows.count

    rows.count.times.each do |row|
      rows.first.count.times.each do |col|
          allow(worksheet).to receive(:numeric_value).with(row + 1, col + 1).and_return rows[row][col].to_money.to_f
      rescue Monetize::ParseError
          next
      end
    end

    allow_any_instance_of(GoogleSpreadsheet).to receive(:worksheet).and_return(worksheet)
  end
end
