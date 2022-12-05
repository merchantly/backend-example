class ViberService
  def initialize(params)
    @params = params || raise('no params')
  end

  def perform
    case params[:event]
    when 'webhook'
      webhook
    when 'subscribed'
      subscribed
    when 'conversation_started'
      conversation_started
    when 'message'
      message
    end
  end

  private

  attr_reader :params

  def webhook
    nil
  end

  def message
    return if params[:message][:type] != 'text'

    case params[:message][:text]
    when /categories-\d+/
      categories
    when /goods-\d+/
      goods
    when /good-\d+/
      good
    when 'back-shops'
      shops
    else
      default
    end
  end

  def shops
    buttons = list_shops.map do |shop|
      {
        Columns: 2,
        Rows: 2,
        Text: "<font color=\"#{shop[:color_text]}\"><b>#{shop[:name]}</b></font>",
        TextSize: 'large',
        TextHAlign: 'center',
        TextVAlign: 'center',
        ActionType: 'reply',
        ActionBody: "categories-#{shop[:id]}",
        Image: shop[:image]
      }
    end

    msg = {
      keyboard: {
        Type: 'keyboard',
        Buttons: buttons
      }
    }

    send_message(msg)
  end

  def categories
    shop_id = params[:message][:text].split('-').second.to_i

    buttons = list_categories(shop_id).map do |category|
      {
        Columns: 2,
        Rows: 2,
        Text: "<font color=\"#494E67\"><b>#{category.name}</b></font>",
        TextSize: 'large',
        TextHAlign: 'center',
        TextVAlign: 'center',
        ActionType: 'reply',
        ActionBody: "goods-#{category.id}",
        BgColor: '#f6f5f9'
      }
    end

    buttons << {
      Columns: 2,
      Rows: 2,
      Text: '<font color=\"#494E67\"><b>Назад</b></font>',
      TextSize: 'large',
      TextHAlign: 'center',
      TextVAlign: 'center',
      ActionType: 'reply',
      ActionBody: 'back-shops',
      BgColor: '#f6f5f9'
    }

    shop_text = list_shops.find { |s| s[:id] == shop_id }[:text]

    msg = {
      type: 'text',
      text: "#{shop_text}.\nКакие товары вас интересуют?",
      keyboard: {
        Type: 'keyboard',
        Buttons: buttons
      }
    }

    send_message(msg)
  end

  def goods
    category_id = params[:message][:text].split('-').second.to_i

    buttons = []

    list_goods(category_id).each do |good|
      buttons << {
        Columns: 2,
        Rows: 2,
        Image: good.image.try(:adjusted_url, width: 300, height: 300),
        ActionType: 'reply',
        ActionBody: "good-#{good.id}"
      }

      buttons << {
        Columns: 4,
        Rows: 2,
        Text: "<font color=\"#494E67\"><b>\u00a0\u00a0#{good.name}</b><br>\u00a0#{good.price} руб.</font>",
        TextSize: 'large',
        TextHAlign: 'left',
        TextVAlign: 'top',
        ActionType: 'reply',
        ActionBody: "good-#{good.id}",
        BgColor: '#ffffff'
      }
    end

    category_name = Category.find(category_id).name

    msg = {
      type: 'text',
      text: "Вот некоторые товары из категории #{category_name}",
      keyboard: {
        Type: 'keyboard',
        Buttons: buttons
      }
    }

    send_message(msg)
  end

  def subscribed
    msg = {
      type: 'text',
      text: "Добро пожаловать в kiiiosk!\nВыберите магазин"
    }

    send_message(msg)

    shops
  end

  def conversation_started
    shops
  end

  def good
    id = params[:message][:text].split('-').second.to_i

    good = Product.find(id)

    msg = {
      type: 'picture',
      text: "Купить #{Rails.application.routes.url_helpers.vendor_product_url(id: good, host: good.vendor.home_url)}",
      media: good.image.try(:adjusted_url, width: 300, height: 300)
    }

    send_message(msg)

    default
  end

  def default
    conversation_started
  end

  def list_goods(category_id)
    Product.by_deep_categories(Category.find(category_id)).published.first(12)
  end

  def list_categories(shop_id)
    Vendor.find(shop_id).menu_categories.first(5)
  end

  def list_shops
    [
      { id: 68, name: 'Сахарок', image: 'http://kiiiosk.store/viber/saharok.png', text: 'Saharok - магазин минималистичных украшений', color_text: '#ffffff' },
      { id: 5, name: 'WANNA?BE!', image: 'http://kiiiosk.store/viber/wannabe.png', text: 'Wannabe.', color_text: '#ffffff' },
      { id: 575, name: '365 detox', image: 'http://kiiiosk.store/viber/365detox.png', text: '365 detox - детокс каждый день', color_text: '#ffffff' },
      { id: 31, name: 'SPUTNIK', image: 'http://kiiiosk.store/viber/sputnik.png', text: 'Sputnik - надежные и красивые городские рюкзаки в России', color_text: '#ffffff' },
      { id: 131, name: 'VARVARA', image: 'http://kiiiosk.store/viber/varvara.png', text: 'Varvara - магазин одежды и аксессуаров с русским акцентом', color_text: '#ffffff' },
      { id: 1233, name: 'Честная ферма', image: 'http://kiiiosk.store/viber/ferma.png', text: 'Честная ферма - доставка продуктов с рынков Москвы', color_text: '#ffffff' }
    ]
  end

  def send_message(msg)
    msg[:auth_token] = auth_token
    msg[:receiver] = (params[:sender].try(:[], :id) || params[:user].try(:[], :id) || params[:user_id])

    HTTP.post('https://chatapi.viber.com/pa/send_message', json: msg)
  end

  def auth_token
    @auth_token ||= Secrets.viber.auth_token
  end
end
