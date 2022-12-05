# Это такой замысловатый спосбо добавить поддомен в запрос для rspec
#
# Использовать:
#
# RSpec.configure do |config|
#   config.include ProcessWithRequestSubdomain, type: :controller
#

module ProcessWithRequestSubdomain
  extend ActiveSupport::Concern
  module ClassMethods
    module WithSubdomain
      REQUEST_KWARGS = %i(params headers env xhr format)
      def kwarg_request?(args)
        args[0].respond_to?(:keys) && args[0].keys.any? { |k| REQUEST_KWARGS.include?(k) }
      end

      def process(action, *args)
        if kwarg_request?(args)
          args.first.deep_merge! params: { subdomain: request.subdomain } if request.subdomain.present?
        elsif args.count == 1
          args[0][:params] = { subdomain: request.subdomain } if request.subdomain.present?
        else
          args[1] ||= {}
          args[1][:subdomain] = request.subdomain if request.subdomain.present?
        end

        super(action, *args)
      end
    end

    def new(*)
      super.extend(WithSubdomain)
    end
  end
end
