module MoyskladImporting
  module EntitiesFilter
    # #<Moysklad::Entities::StockTO:0x007f403a951970
    #  @category="Браслет-нить",
    #  @consignmentName="Браслет-нить Маска родий красный",
    #  @goodRef=
    #    %<65d01369Moysklad::Entities::GoodRef:0x007f403a961578
    #      @code=nil,
    #      @name="Браслет-нить Маска родий красный",
    #      @objectType="Good",
    #      @uuid="04702e7d-8acd-11e4-90a2-8ecb0019a36f">,
    #  @parentUuid="82cd6ad1-7b1f-11e4-7a07-673d0012ad1c",
    #  ...
    #
    # Чтобы отфильтровать сущности, в качестве filter нужно передать hash вида:
    # {parentUuid: '82cd6ad1-7b1f-11e4-7a07-673d0012ad1c'}
    # {parentUuid: ['82cd6ad1-7b1f-11e4-7a07-673d0012ad1c','047034f9-8acd-11e4-90a2-8ecb0019a373', ...]}}
    # {goodRef: {uuid: '04702e7d-8acd-11e4-90a2-8ecb0019a36f'}}
    # {goodRef: {uuid: ['04702e7d-8acd-11e4-90a2-8ecb0019a36f','047034f9-8acd-11e4-90a2-8ecb0019a373', ...]}}
    def check(entity, filter)
      filter.select do |method, expected_value|
        entity_value = entity.send method

        case expected_value
        when Hash
          check(entity_value, expected_value) == expected_value

        when Array
          expected_value.include? entity_value

        else
          entity_value == expected_value
        end
      end
    end

    def filtered?(entity)
      check(entity, filter) == filter
    end
  end
end
