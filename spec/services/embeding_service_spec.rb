require 'rails_helper'

describe EmbedingService do
  subject { described_class.new(video_url: video_url).perform }

  describe do
    let(:video_url) { 'https://www.youtube.com/watch?v=4MdefpBbEn4' }

    specify do
      expect(subject).to include 'https://www.youtube.com/embed/4MdefpBbEn4?rel=0&showinfo=0'
    end
  end

  describe do
    let(:video_url) { 'https://youtu.be/7Ypi5HHbhsQ' }

    specify do
      expect(subject).to include 'https://www.youtube.com/embed/7Ypi5HHbhsQ?rel=0&showinfo=0'
    end
  end
end
