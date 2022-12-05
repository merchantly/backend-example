require 'rails_helper'

RSpec.describe MailTemplate, type: :model do
  subject { create :mail_template, vendor: vendor }

  let!(:vendor) { create :vendor }
  let(:minimal_length) { 20 }

  it 'validate factored' do
    expect(subject).to be_valid
  end

  I18n.available_locales.each do |locale|
    MailTemplate::NAMESPACES.each do |ns|
      described_class.namespace_keys(ns).each do |key|
        it "template '#{ns}:#{key}:#{locale}':" do
          template = vendor.mail_templates.get(key: key, namespace: ns, locale: locale)
          context = template.context_example
          expect(template.eval_subject(context).length).to be > 0
          expect(template.to_sms(context).length).to be > minimal_length
          expect(template.default_content_html.length).to be > 0
          expect(template.default_content_text.length).to be > 0
          expect(template.to_html(context).length).to be > minimal_length
          expect(template.to_text(context).length).to be > minimal_length
          expect(template).to be_valid
          expect(template.save).to be_truthy
        end
      end
    end
  end

  context do
    subject { build :mail_template, key: :wrong }

    it { expect(subject).not_to be_valid }
  end
end
