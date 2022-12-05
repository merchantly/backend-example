# Импорт из Yandex ML
# https://partner.market.yandex.ru/legal/tt/?ncrnd=4981

class YMLCatalog::Import
  class CategoryNotFound < StandardError
    def message
      "В файле нет данных о категории #{super}, хотя на нее ссылаются другие как на родительскую"
    end
  end

  def initialize(vendor: nil, body: nil, inspector: nil)
    @vendor = vendor or raise 'No vendor specified'
    @body   = body or raise 'No body specified'
    inspector ||= JobInspector::Base.new
    raise 'inspector must be a JobInspector' unless inspector.is_a? JobInspector::Base

    @inspector = inspector
  end

  def perform
    raise 'No yml_catalog in root' if doc.xpath('/yml_catalog').blank?

    @errors = []

    @total_categories = doc.xpath('/yml_catalog/shop/categories/category').count
    @total_offers = doc.xpath('/yml_catalog/shop/offers/offer').count
    total = @total_categories + @total_offers

    raise 'Empty yml catalog' if total.zero?

    inspector.total = total

    inspector.details = "Категорий: #{@total_categories}\nТоварных предложений: #{@total_offers}"
    import_currencies
    import_categories
    import_offers

    inspector.details = ([inspector.details] + @errors).join(";\n") if @errors.count.positive?

    inspector.finish
  end

  private

  attr_reader :vendor, :body, :inspector

  def import_currencies
    @currencies = {}
    doc.xpath('/yml_catalog/shop/currencies/currency').each do |node|
      rate = node.attr 'rate'
      name = node.attr 'id'
      @currencies[name] = rate
    end
  end

  def import_categories
    buffer = {}
    doc.xpath('/yml_catalog/shop/categories/category').each do |node|
      buffer[node.attr('id')] = { name: node.text, parent_id: node.attr('parentId') }
    end

    @categories = {}

    buffer.each_key do |id|
      @categories[id] = find_or_create_category(id, buffer)
      inspector.increment
    end
  end

  def find_or_create_category(id, buffer)
    cat = @categories[id]
    return cat if cat.present?

    data = buffer[id] || raise(CategoryNotFound, id)

    Category.find_or_create_by_name vendor, data[:name], get_parent_category(data[:parent_id], buffer)
  end

  def get_parent_category(id, buffer)
    return unless id

    @categories[id] || find_or_create_category(id, buffer)
  end

  def import_offers
    # pb = ProgressBar.create title: 'Offers', total: @total_offers
    doc.xpath('/yml_catalog/shop/offers/offer').each do |node|
      import_offer node
      # pb.increment
      inspector.increment
    end
    # pb.finish
  end

  def property_type
    if vendor.disabled_dictionary_entity_counters?
      PropertyString
    else
      PropertyDictionary
    end
  end

  def import_offer(node)
    is_manual_published = node.attr('available') == 'true'
    title = node.xpath('name').text.presence || node.xpath('model').text
    title.squish!
    title = 'No title' if title.blank?
    description = node.xpath('description').text

    Rails.logger.debug { "[#{vendor.id}] YML:Импортурею '#{title}'" }

    currency = get_currency node.xpath('currencyId').text
    price = Money.new node.xpath('price').text.to_f * 100, currency

    cat_id = node.xpath('categoryId').text
    category = get_category cat_id

    product = vendor.products.by_title(title).first || Product.new(vendor: vendor)
    product.restore if product.archived?

    brand = node.xpath('vendor').text
    product.set_attribute_by_key :brand, brand if brand.present? && brand != 'none'

    node.xpath('param').each do |attr_node|
      product.set_attribute_by_key attr_node.attr(:name), attr_node.text, property_type
    end

    product.update!(
      title: title,
      description: description,
      category: category,
      price: price,
      is_manual_published: is_manual_published
    )

    pictures = node.xpath('picture').map(&:text)

    pictures.each do |pic|
      add_image product, pic
    end
  rescue StandardError => e
    @errors << "product:#{node}:#{e.message}"
  end

  def add_image(product, image_url)
    return if product.images.exists?(saved_remote_image_url: image_url)

    product.add_image_by_url image_url
  rescue StandardError => e
    @errors << "add_image:#{image_url}:#{e.message}"
  end

  def get_currency(name)
    return 'rub' if name.casecmp('rur').zero? || name.casecmp('rub').zero?

    raise("No such currency #{name}") unless @currencies.key? name

    name.downcase
  end

  def get_category(id)
    @categories[id.to_s]
  end

  def doc
    @doc ||= Nokogiri.XML(body)
  end
end
