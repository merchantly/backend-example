class HistoryPath < ApplicationRecord
  DEFAULT_CONTENT_TYPE = 'text/html'.freeze

  extend Enumerize
  include Authority::Abilities

  belongs_to :resource, polymorphic: true
  belongs_to :vendor

  scope :ordered,         -> { order updated_at: :desc }
  scope :not_founds,      -> { with_state :not_found }
  scope :ok,              -> { with_state :ok }
  scope :by_path,         ->(path) { where path: path }
  scope :by_content_type, ->(ct) { where content_type: ct }
  scope :by_query,        ->(path) { where 'path ilike ? or referer like ?', "%#{path}%", "%#{path}%" }

  before_save :set_content_type
  enumerize :state, in: { ok: 0, error: 1, not_found: 2, slugged: 3 }, default: :ok, scope: true

  enumerize :response_state, in: { no_response: 0, ignore: 1 }, default: :no_response, scope: true

  def self.upsert(vendor_id: nil,
                  path: nil,
                  referer: nil,
                  state: :ok,
                  user_agent: nil,
                  controller_name: nil,
                  action_name: nil,
                  resource: nil)
    p = find_by(vendor_id: vendor_id, path: path)

    attrs = {
      state: state,
      action_name: action_name,
      controller_name: controller_name,
      resource: resource
    }
    attrs[:referer]    = referer if referer.present?
    attrs[:user_agent] = user_agent.encode('ascii', invalid: :replace, undef: :replace) if user_agent.present?

    if p.present?
      p.update attrs
      p.increment! :count, 1
    else
      create! attrs.merge(
        vendor_id: vendor_id,
        path: path,
        count: 1
      )
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def safe_resource
    resource
  rescue ActiveRecord::RecordNotFound
    nil
  end

  private

  def set_content_type
    self.content_type = detect_content_type if HistoryPath.attribute_names.include? 'content_type' # TODO remove after release
  end

  def detect_content_type
    MimeMagic.by_path(path).try(:type) || DEFAULT_CONTENT_TYPE
  end
end
