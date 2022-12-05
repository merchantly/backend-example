class MemberAccessTokenizer < OneOffAccessTokenService
  include Singleton

  NO_MEMBER = 'no_member-'.freeze

  NS = 'one_off_access_tokens:members'.freeze

  class << self
    delegate :find, :generate, to: :instance
  end

  def generate(member)
    raise "Must be Member #{member.class}" unless member.is_a? Member
    raise "Must be persisted member #{member}" unless member.persisted?

    super member.id
  end

  def find(vendor, token)
    raise "Must be a vendor #{vendor}" unless vendor.is_a? Vendor
    raise 'Must be present string' unless token.is_a?(String) && token.present?
    return if token == NO_MEMBER

    id = super token

    if id.present?
      member = vendor.members.find_by id: id
      return member if member.present?

      Bugsnag.notify "No such member #{id} for vendor #{vendor.id}", metaData: { member_id: id, vendor_id: vendor.id }
    end

    nil
  end
end
