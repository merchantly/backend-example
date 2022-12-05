require 'rails_helper'

RSpec.describe 'operator/properties/index', type: :view do
  before do
    create :property_string, vendor: vendor
    create :property_dictionary, vendor: vendor

    view.lookup_context.prefixes << 'operator/products'
    view.lookup_context.prefixes << 'application'
    controller.singleton_class.class_eval do
      protected

      def resource
        true
      end

      def active_tab
        :one
      end
      helper_method :resource
      helper_method :active_tab
    end
  end

  it do
    render template: 'operator/properties/index', locals: { properties: vendor.properties }
    expect(view).to render_template('operator/properties/index')
  end
end
