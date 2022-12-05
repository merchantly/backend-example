class Theme
  include Virtus.model
  attribute :key,   String
  attribute :title, String
  attribute :body_class, String

  def self.all
    Settings::Themes.all.keys.map do |key|
      Theme.new Settings::Themes.all[key].merge key: key
    end
  end

  def self.find(key)
    all.find { |theme| theme.key == key }
  end

  def self.as_collection
    all.map do |theme|
      [theme.title, theme.key]
    end
  end
end
