require 'rails_helper'

describe 'mail templates' do
  MAIL_TEMPLATES_DIR = 'app/views/mail_templates/'.freeze

  let!(:order) { create :order }
  let!(:order_drop) { OrderDrop.new order }

  it 'test all templates in app/views/mail_templates' do
    Dir["#{MAIL_TEMPLATES_DIR}*.liquid"].sort.each do |file|
      template = Liquid::Template.parse File.read(file), error_mode: :strict
      buff = template.render!({ 'order' => order_drop }, filters: [LiquidFilters])

      expect(buff).to be_a String
    end
  end
end
