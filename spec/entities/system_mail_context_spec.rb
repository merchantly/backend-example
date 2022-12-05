require 'rails_helper'

RSpec.describe SystemMailContext, type: :model do
  subject { described_class.new template: template, operator: operator, vendor: vendor }

  let(:vendor) { create :vendor }
  let(:operator) { create :operator }
  let(:template) { VendorNotifyMailTemplate.get(key: template_key, locale: I18n.locale) }

  VendorNotifyMailTemplate::TYPES.each do |type|
    let(:template_key) { type }
    it do
      expect { subject.subject }.not_to raise_error
      expect { subject.content }.not_to raise_error
    end
  end
end
