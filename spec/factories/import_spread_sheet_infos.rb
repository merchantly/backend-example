# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :import_spread_sheet_info do
    vendor { nil }
    google_spreadsheet_url { 'https://docs.google.com/spreadsheets/d/14yUn83OTVSdMM6mGU2ozmk-dl6rKCawAjVrVXPpETeI/edit#gid=0' }
    state { 1 }
    skip_rows { 1 }
    rows { [] }
    locale { 'ru' }
  end
end
