require 'rails_helper'

describe TitleLiquidRenderer do
  let(:vendor) { create :vendor }

  let(:template) { '{{resource.title}} - {{vendor.name}}' }

  describe 'рендерятся все ресурсы' do
    TitleLiquidRenderer::RESOURCES.each do |table_name|
      context table_name do
        subject { described_class.new(template: template, vendor: vendor).render resource }

        let(:resource) { table_name == 'vendors' ? vendor : create(table_name.singularize, vendor: vendor) }

        specify 'рендерится без ошибок' do
          expect(subject).to be_a String
          expect(subject).not_to include 'Error'
        end
      end
    end
  end
end
