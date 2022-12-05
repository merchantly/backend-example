module ExistenVendors
  extend ActiveSupport::Concern

  module ClassMethods
    def default
      wannabe || Vendor.first
    end

    def chestnayaferma
      @chestnayaferma ||= Vendor.find_by_domain 'chestnayaferma.ru'
    end

    def jelleryru
      @jelleryru ||= Vendor.find(162)
    end

    def litkz
      @litkz ||= Vendor.find(36)
    end

    def demo
      @demo ||= Vendor.find_by(subdomain: 'demo')
    end

    # Магазин-шаблон для копирования при создании
    #
    def template
      @template ||= Vendor.find_by(id: 2087)
    end

    def ppap
      @ppap ||= Vendor.find_by(subdomain: 'ppap')
    end

    def sputnik
      @sputnik ||= Vendor.find_by(subdomain: 'sputnik')
    end

    def dapi
      @dapi ||= Vendor.find_by(subdomain: 'dapi')
    end

    def saharok
      @saharok ||= Vendor.find_by(subdomain: 'saharok')
    end

    def wannabe
      @wannabe ||= Vendor.find_by_domain('wanna-be.ru')
    end

    def etc
      @etc ||= Vendor.find_by_domain('etc.kiiiosk.store')
    end

    def cc
      @cc ||= Vendor.find_by_domain('cc.kiiiosk.store')
    end
  end
end
