module VendorTitleTemplates
  extend ActiveSupport::Concern

  included do
    translates :meta_title_templates do |attr_name, locale|
      TitleLiquidRenderer::RESOURCES.each do |resource|
        define_method "#{attr_name}_#{locale}_#{resource}" do
          (read_translation(attr_name, locale) || {})[resource]
        end

        define_method "#{attr_name}_#{locale}_#{resource}=" do |value|
          translations = (read_translation(attr_name, locale) || {}).merge resource => value
          write_translation(attr_name, translations, locale)
        end
      end
    end
  end
end
