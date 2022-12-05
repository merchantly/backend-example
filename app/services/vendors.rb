module Vendors
  class Wannabe
    def parse_product_article(source)
      a = source.split('-')
      if a.last.casecmp('u').zero?
        source
      else
        source.split('-')[0, 2].join('-')
      end
    end
  end
end
