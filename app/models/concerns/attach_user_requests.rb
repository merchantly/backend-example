module AttachUserRequests
  extend ActiveSupport::Concern

  included do
    after_save :attach_user_request
  end

  private

  def attach_user_request
    if phone.present?
      UserRequest.no_vendor.where(clean_phone: phone).update_all vendor_id: vendor_id
    end
    if email.present?
      UserRequest.no_vendor.where(email: email).update_all vendor_id: vendor_id
    end
  end
end
