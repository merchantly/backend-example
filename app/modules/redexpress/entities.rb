module Redexpress::Entities
  class FlowInfo
    include HappyMapper

    tag :flowInfo

    element :seqNo,      Integer
    element :dealTime,   Time
    element :mailStatus, String
    element :mailStatusDescription, String
    element :dealCountry, String
    element :dealCity,    String
    element :remark, String
  end

  class Mail
    include HappyMapper
    tag :mail

    element :mailCode,       Integer
    element :orderNumber,    Integer
    element :invoiceCompany, String
    element :status,         String, tag: 'currStatus'
    element :description,    String, tag: 'currStatusDescription'
    element :currCity,       String
    element :currCountry,    String
    element :time,           Time, tag: 'currDealTime'

    has_many :flowInfo, FlowInfo

    def time
      return Time.zone.now if @time == Time.new(1)

      @time
    end
  end

  class Mails
    include HappyMapper
    tag :mails
    element :mailNum, Integer
    element :mail, Mail

    delegate :description, :time, :status, to: :mail

    def persisted?
      mailNum.positive?
    end
  end
end
