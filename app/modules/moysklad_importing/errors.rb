module MoyskladImporting
  module Errors
    attr_reader :entity, :id, :type

    class NoRelationFound < StandardError
      def initialize(entity, id, type = :unknown)
        binding.debug_error
        @entity = entity
        @id = id
        @type = type
      end

      def to_s
        message
      end

      def message
        I18n.t('errors.ms.relative_element_not_found', type: @type, id: @id, entity_class: @entity.class, entity_id: @entity.id)
      end
    end

    class NoConsignmentForGood < NoRelationFound
      def initialize(assortment)
        binding.debug_error
        @consignment_id = assortment.id
        @good_id = assortment.meta.id
        @type = assortment.meta.href
      end

      def message
        I18n.t 'errors.ms.no_consignment_for_good', consignment_id: @consignment_id, id: @good_id, type: @type
      end
    end

    class NoLocalRelationFound < NoRelationFound
      def message
        I18n.t 'errors.ms.local_relative_element_not_found', type: @type, id: @id, entity_class: @entity.class, entity_id: @entity.id
      end
    end
  end
end
