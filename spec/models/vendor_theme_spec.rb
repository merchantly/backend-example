require 'rails_helper'

RSpec.describe VendorTheme, type: :model do
  subject { create :vendor_theme }

  it { expect(subject).to be_valid }
  it { expect(subject).to be_a described_class }

  describe 'trims spaces in w1_widget_ptenabled' do
    before { subject.update w1_widget_ptenabled: 'CreditCardRUB, MobileRetailsRUB' }

    it { expect(subject.w1_widget_ptenabled).to eq 'CreditCardRUB,MobileRetailsRUB' }
  end

  describe '#render_style' do
    let!(:custom_style_sass) { "$var: 123px\n.x\n  width: $var\n" }
    let!(:custom_style_scss) { '$var: 123px; .x{ width: $var; }' }
    let!(:custom_style_css)  { ".x {\n  width: 123px; }\n" }

    context 'sass' do
      before do
        subject.update custom_style: custom_style_sass, custom_style_format: 'SASS'
      end

      it 'must render css' do
        expect(subject.render_style).to eq custom_style_css
      end
    end

    context 'scss' do
      before do
        subject.update custom_style: custom_style_scss, custom_style_format: 'SCSS'
      end

      it 'must render css' do
        expect(subject.render_style).to eq custom_style_css
      end
    end
  end
end
