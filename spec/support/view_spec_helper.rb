module ViewSpecHelper
  extend ActiveSupport::Concern
  # include CurrentVendor

  class ReactComponentHelperStub
    def react_component(*args)
      args
    end
  end

  included do
    let!(:rch) { ReactComponentHelperStub.new }
    let!(:vendor) { create :vendor }

    before do
      Thread.current[:vendor] = vendor

      @new_helper = React::Rails::ViewHelper.helper_implementation_class.new
      @new_helper.setup(self)
      assign :__react_component_helper, @new_helper
    end

    after do
      @new_helper.teardown(self)

      Thread.current[:vendor] = nil
    end
  end

  module ControllerViewHelpers
    # Это заглушки, чтобы во view были методы
    # которые можно застабить.

    delegate :session, to: :request

    def current_wishlist
      raise 'current_wishlist is not stubbed'
    end

    def current_vendor
      Thread.current[:vendor]
    end

    def current_member
      nil
    end

    def backurl; end

    def current_operator
      nil
    end

    def current_currency
      current_vendor.default_currency
    end

    def url_for(opts)
      opts.is_a?(Hash) && opts.key?(:locale) ? nil : super(opts)
    end
  end

  def initialize_view_helpers(view)
    view.extend ControllerViewHelpers
  end
end
