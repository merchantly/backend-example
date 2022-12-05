require 'rails_helper'

describe DeliveryTimeResolver do
  subject { described_class.perform(vendor_delivery: vendor_delivery, current_time: current_time).first }

  let!(:vendor_delivery) { create :vendor_delivery }

  let!(:first_rule) { create :delivery_time_rule,  to: '12:00', time: '19:00', days_count: 0, vendor_delivery: vendor_delivery }
  let!(:second_rule) { create :delivery_time_rule, to: '16:45', time: '12:00', days_count: 1, vendor_delivery: vendor_delivery }
  let!(:third_rule) { create :delivery_time_rule, to: '22:00', time: '19:00', days_count: 1, vendor_delivery: vendor_delivery }
  let!(:default_rule) { create :delivery_time_rule, to: '00:00', time: '12:00', days_count: 2, vendor_delivery: vendor_delivery, is_default: true }

  let!(:time_periods) { [{ from: '9', to: '12' }, { from: '12', to: '18' }, { from: '19', to: '22' }] }

  let!(:time_slots) do
    [
      create(:delivery_time_slot, date: current_time.to_date, vendor_delivery: vendor_delivery, delivery_time_periods_attributes: time_periods),
      create(:delivery_time_slot, date: (current_time + 1.day).to_date, vendor_delivery: vendor_delivery, delivery_time_periods_attributes: time_periods),
      create(:delivery_time_slot, date: (current_time + 2.days).to_date, vendor_delivery: vendor_delivery, delivery_time_periods_attributes: time_periods)
    ]
  end

  describe '11:00' do
    let!(:current_time) { Time.zone.local(2018, 7, 11, 11, 0, 0) }

    it do
      expect(subject.date).to eq Date.new(2018, 7, 11)
      expect(subject.from.hour).to eq 19
      expect(subject.to.hour).to eq 22
    end
  end

  describe '15:00' do
    let!(:current_time) { Time.zone.local(2018, 7, 11, 15, 0, 0) }

    it do
      expect(subject.date).to eq Date.new(2018, 7, 12)
      expect(subject.from.hour).to eq 12
      expect(subject.to.hour).to eq 18
    end
  end

  describe '19:00' do
    let!(:current_time) { Time.zone.local(2018, 7, 11, 19, 0, 0) }

    it do
      expect(subject.date).to eq Date.new(2018, 7, 12)
      expect(subject.from.hour).to eq 19
      expect(subject.to.hour).to eq 22
    end
  end

  describe '23:00' do
    let!(:current_time) { Time.zone.local(2018, 7, 11, 23, 0, 0) }

    it do
      expect(subject.date).to eq Date.new(2018, 7, 13)
      expect(subject.from.hour).to eq 12
      expect(subject.to.hour).to eq 18
    end
  end
end
