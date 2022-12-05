# Формирует RSS для выгрузки в Yandex Турбо-страницы
#
class ExportYandexTurbo
  # Спека: https://yandex.ru/dev/turbo/doc/rss/markup.html/
  #
  RSS_ATTRIBUTES = {
    'xmlns:yandex' => 'http://news.yandex.ru',
    'xmlns:media' => 'http://search.yahoo.com/mrss/',
    'xmlns:turbo' => 'http://turbo.yandex.ru',
    'version' => '2.0'
  }.freeze

  def initialize(vendor)
    @vendor = vendor
  end

  def call
    Nokogiri::XML::Builder.new(encoding: 'utf-8') do |xml|
      # xml.doc.create_internal_subset('rss', nil, 'shops.dtd')
      xml.rss(RSS_ATTRIBUTES) do
        xml.channel do
          xml.link vendor.public_url
          xml.title vendor.name
          xml.description vendor.description if vendor.description.present?
          xml.language 'ru'

          add_blog_posts vendor, xml
          add_content_pages vendor, xml
        end
      end
    end
  end

  private

  attr_reader :vendor

  def add_blog_posts(vendor, xml)
    vendor.blog_posts.where(use_in_turbo_pages: true).alive.ordered.find_each do |bp|
      content = concat_header(bp.content, bp.title)
      if content.present?
        xml.item turbo: true do
          xml.link bp.public_url
          xml.pubDate bp.created_at.rfc822
          xml.send 'turbo:topic', bp.title
          xml.send 'turbo:content' do
            xml.cdata content
          end
        end
      end
    end
  end

  def add_content_pages(vendor, xml)
    vendor.content_pages.where(use_in_turbo_pages: true).alive.ordered.find_each do |cp|
      content = concat_header(cp.content, cp.title)
      if content.present?
        xml.item turbo: true do
          xml.link cp.public_url
          xml.pubDate cp.created_at.rfc822
          xml.send 'turbo:topic', cp.title
          xml.send 'turbo:content' do
            xml.cdata content
          end
        end
      end
    end
  end

  def concat_header(content, header = nil)
    return '' if content.blank?

    html = Nokogiri::HTML.fragment(content)
    # Удаляем все стили
    html.xpath('@style|.//@style').remove
    html.xpath('@id|.//@id').remove
    html = HTMLEntities.new.decode html.to_html

    # Удаляем ужание изображений типа
    # https://thumbor9.kiiiosk.store/unsafe/500x0/filters:no_upscale()/
    html.gsub!(/http[^"]*filters:no_upscale\(\)\//, '')
    return html if header.blank?

    "<header><h1>#{header}</h1></header>#{html}"
  end

  def cdata(text)
    return '' if text.blank?

    "<![CDATA[#{text}]]>"
  end
end
