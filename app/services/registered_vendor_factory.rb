class RegisteredVendorFactory
  MIN_PERIOD = 5.minutes

  attr_accessor :vendor_registration_form, :vendor, :operator, :user_history, :remote_ip, :locale

  def initialize(vendor_registration_form:, remote_ip:, locale:, current_operator: nil, user_history: nil)
    self.vendor_registration_form = vendor_registration_form
    self.operator = current_operator
    self.user_history = user_history
    self.remote_ip = remote_ip
    self.locale = locale
  end

  def self.with_vendor(vendor)
    rvf = new VendorRegistrationForm.new
    rvf.vendor = vendor
    rvf
  end

  def build
    raise VendorRegistrationError::NotUniquePhone if operator.blank? && vendor_registration_form.is_a?(VendorRegistrationForm) && !unique_phone?
    raise VendorRegistrationError::MinPeriod if operator.present? && operator.vendors.maximum(:registration_at) && (operator.vendors.maximum(:registration_at) > MIN_PERIOD.ago)

    member = nil

    ActiveRecord::Base.transaction do
      register_vendor
      # вместо default методов - копируем демо магазин в продакшн среде
      DefaultDictionaries.new(vendor).perform
      DefaultOrderConditions.new(vendor).perform
      create_default_order_operator_filters

      create_default_payments_and_deliveries! if Settings::Features.create_default_payments_and_deliveries

      create_default_cashier if vendor.default_cashier.blank?
      create_default_branch if vendor.default_branch.blank?

      create_default_product_vat_group if vendor.default_product_vat_group.blank?

      vendor.create_default_quantity_units!

      register_operator if operator.blank?
      member = vendor.add_member operator, vendor.roles.owner
    end

    # Октлючил за неуплату
    # SystemAmoCRMVendorNotify.perform_async(vendor.id, member.id) unless Rails.env.development?

    PartnerMailer.register_vendor(vendor.id).try :deliver_later!

    # забрали один предсозданный магазин, создадим еще
    PreCreateVendorWorker.perform_async if Rails.env.production?

    OperatorMailer.vendor_registration(operator.id, vendor.id).deliver!

    operator
  end

  private

  def create_default_cashier
    cashier = vendor.cashiers.create! name: t('default_cashier')

    vendor.update_column :default_cashier_id, cashier.id
  end

  def create_default_branch
    branch = vendor.branches.create! name: t('default_branch'), cashier_id: vendor.default_cashier_id

    vendor.update_column :default_branch_id, branch.id
  end

  def create_default_product_vat_group
    default_product_vat_group = DefaultProductVatGroup.default

    product_vat_group = vendor.product_vat_groups.create!(
      title: I18n.t(:default_product_vat_group, scope: 'services.vendor_registration'),
      vat: default_product_vat_group.vat
    )

    vendor.update_column :default_product_vat_group_id, product_vat_group.id
  end

  def default_product_image; end

  def default_product_price
    Money.new 200_00, vendor.default_currency
  end

  def create_default_payments_and_deliveries!
    # archive template vendor payments and deliveries
    vendor.vendor_payments.each(&:archive!)
    vendor.vendor_deliveries.each(&:archive!)

    vendor_delivery = vendor.vendor_deliveries.create! delivery_agent_type: OrderDeliveryPickup.name, title: t(:default_pickup)

    {
      default_cash: VendorPaymentKeys::CASH_KEY,
      default_card: VendorPaymentKeys::TERMIAL_PAYMENT_KEY
    }.each do |k, v|
      vendor.vendor_payments.create!(
        payment_agent_type: OrderPaymentDirect.name,
        title_translations: HstoreTranslate.translations(k, %i[services vendor_registration]),
        payment_key: v,
        vendor_delivery_ids: vendor_delivery.id
      )
    end
  end

  def create_default_order_operator_filters
    vendor.workflow_states.ordered.each do |state|
      vendor.order_operator_filters.create!(workflow_state_id: state.id, name_translations: state.name_translations, row_order: state.position)
    end
  end

  def create_vendor
    vendor_template = vendor_registration_form.vendor_template || VendorTemplate.default
    vendor_template.present? ? vendor_template.next_precreated_vendor! : VendorCloneWorker.new.direct_perform(from_vendor: Vendor.demo)
  end

  def register_vendor
    self.vendor = create_vendor

    vendor.name = vendor_registration_form.vendor_name if vendor_registration_form.vendor_name.present?

    vendor.assign_attributes(
      support_email: support_email,
      domain_zone: domain_zone,
      remote_ip: remote_ip,
      is_published: false,
      is_pre_create: false,
      registration_at: DateTime.current,
      default_locale: locale,
      uuid: uuid
    )

    %i[partner_coupon_code vendor_template_id ym_client_id].each do |attr|
      vendor.send "#{attr}=", vendor_registration_form.send(attr)
    end

    assign_referers

    vendor.save!

    vendor
  end

  def assign_referers
    return if user_history.blank?

    vendor.last_referer = user_history.last_referer
    vendor.init_referer = user_history.init_referer
    vendor.init_utm     = user_history.init_utm if user_history.init_utm.present?
    vendor.last_utm     = user_history.last_utm if user_history.last_utm.present?
  end

  def support_email
    operator.try(:email) || form_email
  end

  def form_email
    vendor_registration_form.email if vendor_registration_form.is_a? VendorRegistrationForm
  end

  def domain_zone
    vendor_registration_form.domain_zone
  end

  def subdomain
    UniqueSubdomain.build vendor_registration_form.vendor_name.to_s
  end

  def uuid
    vendor_registration_form.uuid.presence || SecureRandom.uuid
  end

  def register_operator
    self.operator = Operator.create!(
      name: operator_name,
      email: vendor_registration_form.email,
      phone: vendor_registration_form.phone,
      system_subscriptions: SystemMailTemplate::TYPES
    )

    operator.create_partner(name: operator.name)
  end

  def operator_name
    vendor_registration_form.operator_name.presence || t(:operator_name, vendor: vendor_registration_form.vendor_name)
  end

  def unique_phone?
    !Operator.where.not(id: operator.try(:id)).by_phone(vendor_registration_form.phone).exists?
  end

  def t(key, options = {})
    I18n.t key, options.merge(scope: 'services.vendor_registration')
  end
end
