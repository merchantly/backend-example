class RenameRuToStoreService
  include AutoLogger

  def perform
    Vendor.alive.find_each do |vendor|
      %i[
        pre_products_text
        post_products_text
        custom_product_html
        title
        footer_menu_middle_html
        custom_head_html
        custom_append_html
        custom_after_content_html
      ].each do |attribute|
        value = vendor.send attribute

        next unless present_and_include?(value)

        logger.info "Vendor:#{vendor.id}:#{attribute}:#{value}"

        vendor.update attribute => rename(value)
      end

      vendor.content_pages.find_each { |cp| rename_content(cp) }
      vendor.text_blocks.find_each { |tb| rename_content(tb) }
      vendor.blog_posts.find_each { |bp| rename_content(bp) }

      vendor.categories.find_each do |c|
        rename_description(c)
        c.update bottom_text: rename(c.bottom_text) if present_and_include?(c.bottom_text)
      end

      vendor.dictionary_entities.find_each { |de| rename_description(de) }
    end
  end

  private

  def rename_description(entity)
    if present_and_include?(entity.description)
      logger.info "#{entity.class}:#{entity.id}:content:#{entity.description}"

      entity.update description: rename(entity.description)
    end
  end

  def rename_content(subject)
    if present_and_include?(subject.content)
      logger.info "#{subject.class}:#{subject.id}:content:#{subject.content}"

      subject.update content: rename(subject.content)
    end
  end

  def rename(str)
    str.gsub('kiiiosk.ru', 'kiiiosk.store')
  end

  def present_and_include?(value)
    value.present? && value.include?('kiiiosk.ru')
  end
end
