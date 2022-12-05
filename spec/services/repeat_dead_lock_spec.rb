require 'rails_helper'

describe RepeatDeadLock do
  it 'возвращает результат' do
    expect(
      described_class.perform { 1 + 1 }
    ).to eq 2
  end

  it do
    expect { described_class.perform { raise PG::TRDeadlockDetected } }.to raise_error RepeatDeadLock::TriesExceed
  end
end
