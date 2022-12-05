class OperatorAccessTokenizer < OneOffAccessTokenService
  include Singleton

  NS = 'one_off_access_tokens:operators'.freeze

  class << self
    delegate :find, :generate, to: :instance
  end

  def generate(operator)
    raise "Must be Operator #{operator.class}" unless operator.is_a? Operator
    raise "Must be persisted operator #{operator}" unless operator.persisted?

    super operator.id
  end

  def find(token)
    raise 'Must be present string' unless token.is_a?(String) && token.present?

    id = super token

    if id.present?
      operator = Operator.find_by id: id
      return operator if operator.present?

      Bugsnag.notify "No such operator #{id}", metaData: { operator_id: id }
    end

    nil
  end
end
