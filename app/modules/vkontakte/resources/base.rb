module Vkontakte
  module Resources
    class Base
      include Virtus.model
      attribute :client, VkontakteApi::Client, required: true

      private

      def try
        error = nil
        try_counter = 0

        loop do
            try_counter += 1
            puts "#{Time.zone.now} TRY counter: #{try_counter}"
            wait_api error.present?
            return yield
        rescue VkontakteApi::Error => e
            binding.debug_error
            error = e
            # => err.message
            # "VKontakte returned an error 9: 'Flood control' after calling method 'photos.createAlbum' with parameters {\"comment_privacy\"=>\"0\", \"comments_disabled\"=>\"0\", \"description\"=>\"\", \"group_id\"=>\"83086022\", \"privacy\"=>\"0\", \"title\"=>\"Браслеты\", \"upload_by_admins_only\"=>\"1\"}."
            if /Flood control/=~e.message
              puts "#{Time.zone.now} Catched Flood control"
            else
              raise e
            end
        rescue StandardError => e
            Bugsnag.notify e
            binding.debug_error
        end
      end

      def wait_api(long = false)
        seconds = long ? 3600 : 0.5
        puts "#{Time.zone.now} Wait API #{seconds} seconds"
        sleep seconds
      end

      def parse_data(data)
        entity_class.new data
      end

      # @return Vkontakte::Entities::Base
      def entity_class
        raise 'not implemented'
      end
    end
  end
end
