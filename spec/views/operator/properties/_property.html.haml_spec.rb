require 'rails_helper'

RSpec.describe 'operator/properties/_property', type: :view do
  before do
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

  context 'string property' do
    let(:property) { create :property_string, vendor: vendor }

    it do
      render_described locals: { property: property }
      expect(view).to render_template('operator/properties/_property')
    end
  end

  context 'string property' do
    let(:property) { create :property_dictionary, vendor: vendor }

    it do
      render_described locals: { property: property }
      expect(view).to render_template('operator/properties/_property')
    end
  end
end
