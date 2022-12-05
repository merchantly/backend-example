module DaData
  class OrderDeliveryCleanAddress
    include Virtus.model

    attribute :order, Order
    attribute :address_service

    def call
      raise DaDataError::UndeterminedAddress.new(parsed_address) if undetermined_address?

      order.update!(
        region: address_data[:region],
        street: address_data[:street],
        house: address_data[:house],
        room: address_data[:flat],
        address_parsed: true
      )
    end

    private

    # fias_level:
    # Уровень детализации, до которого адрес найден в ФИАС:
    #  0 — страна;
    #  1 — регион;
    #  3 — район;
    #  4 — город;
    #  6 — населенный пункт;
    #  7 — улица;
    #  8 — дом;
    #  -1 — иностранный или пустой.
    def undetermined_address?
      parsed_address[:fias_level].to_i < 8
    end

    def address_data
      OrderDeliveryAddressEntity.represent(parsed_address).serializable_hash
    end

    def parsed_address
      @parsed_address ||= address_service.call
    end
  end
end
