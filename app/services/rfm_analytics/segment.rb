module RFMAnalytics
  class Segment
    include Virtus.model

    SEGMENTS = [
      { key: :best_customers, r: 1, f: 1, m: 1, css_class: 'label-danger' },
      { key: :big_spenders, r: nil, f: nil, m: 1, css_class: 'label-info' },
      { key: :loyal_customers, r: nil, f: 1, m: nil, css_class: 'label-success' },
      { key: :recent_customers, r: 1, f: nil, m: nil, css_class: 'label-warning' },
      { key: :almost_lost, r: 3, f: 1, m: 1, css_class: 'label-default' },
      { key: :lost_customers, r: 4, f: 1, m: 1, css_class: 'label-default' },
      { key: :lost_cheap_customers, r: 4, f: 4, m: 4, css_class: 'label-default' },
      { key: :other }
    ].freeze

    attribute :key, Symbol, strict: true
    attribute :r, Integer
    attribute :f, Integer
    attribute :m, Integer
    attribute :css_class, String
    attribute :id, Integer, strict: true

    def self.segments
      @segments ||= SEGMENTS.each_with_index.map do |value, index|
        new value.merge(id: index)
      end
    end

    def self.find(client_segment)
      segments.find { |l| l.include? client_segment }
    end

    # RFMAnalytics::ClientSegment
    #
    def include?(client_segment)
      (r.nil? || client_segment.r == r) &&
        (f.nil? || client_segment.f == f) &&
        (m.nil? || client_segment.m == m)
    end

    def tooltip
      [details, strategy].compact.join('<br/>').html_safe
    end

    def mask
      [r || 'X', f || 'X', m || 'X'].join('-')
    end

    def title
      t :title, default: key
    end

    def details
      t :details
    end

    def strategy
      t :strategy
    end

    def to_s
      title
    end

    private

    def t(i18n_key, default: nil)
      I18n.t i18n_key, scope: [:rfm, :segments, key], default: default
    end
  end
end
