module Vkontakte
  module Resources
    # https://vk.com/dev/groups
    class Groups < Base
      # @param params[Hash]
      def index(params = {})
        params = params.merge extended: 1

        @groups ||= try { client.groups.get(params)['items'] }.map { |data| parse_data data }
      end

      # @param [String] group_id - идентификатор или короткое имя сообщества.
      def get(group_id)
        try { client.groups.get_by_id(group_id: group_id) }.map { |data| parse_data data }
      end

      private

      def entity_class
        ::Vkontakte::Entities::Group
      end
    end
  end
end
