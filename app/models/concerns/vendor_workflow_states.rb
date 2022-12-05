module VendorWorkflowStates
  extend ActiveSupport::Concern
  DEFAULT_STATES = %i[new in_process success failure].freeze

  included do
    after_create :create_default_workflow_states
  end

  private

  def create_default_workflow_states
    DEFAULT_STATES.each do |state|
      rgb = case state.to_sym
            when :new then '#f8ac59'
            when :in_process then '#23c6c8'
            when :success then '#1c84c6'
            when :failure then '#D1DADE'
            else
              raise "Unknown state: #{state}"
            end

      workflow_states.create! name_translations: HstoreTranslate.translations(state, :order_states), finite_state: state, color_hex: rgb, position: :last
    end
  end
end
