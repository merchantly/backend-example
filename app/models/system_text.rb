# класс для вывода различных текстовых(информационных) страниц
class SystemText < ApplicationRecord
  extend Enumerize
  validates :title, :key, :content, presence: true

  # Текст партнерской программы
  KEY_PARTNER_PROGRAM = 'partner_program'.freeze
  # какие бывают(используются)
  KEYS = [KEY_PARTNER_PROGRAM].freeze

  enumerize :key, in: KEYS, scope: true
end
