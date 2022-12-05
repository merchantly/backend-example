# Когда миграция уже выполнена на продакшене
# и нет смысла ее выполнять при каждой миграции
# (например в тестах)
# метод миграции удаляется, а ее название переносится в LEGACY

class ReleaseMigrations
  include MoneyRails::ActionViewExtension
  include MoneyHelper

  LEGACY = [
    :menu, :move_categories_to_products, :vendor_deliveries, :vendor_payments,
    :recalculate_sms_count, :create_order_operator_filters
  ].freeze

  def self.migrate(name, *args)
    return if Rails.env.test?
    return if LEGACY.include? name

    puts "ReleaseMigrations: #{name}"
    send name, *args
    puts "ReleaseMigrations: #{name} - done"
  end

  def self.create_services
    OpenbillService.create! title: 'Store support', account: OpenbillAccount.find(Billing::SUBSCRIPTIONS_ACCOUNT_ID)
    OpenbillService.create! title: 'Disable footer "Made on .."', account: OpenbillAccount.find(Billing::EXTERNAL_LINK_KIOSK_ACCOUNT_ID)
    OpenbillService.create! title: 'Additional works', account: OpenbillAccount.find(Billing::ADDITIONAL_WORKS_ACCOUNT_ID)
  end

  def self.restore_image_digests
    ProductImage.find_each do |pi|
      begin
        pi.send :build_digest
        pi.save
      rescue Errno::ENOENT
        puts "not found: #{pi.id}"
      end
    end
  end

  def self.available_payments_ids
    VendorDelivery.find_each do |d|
      d.available_payments_ids.each do |id|
        d.vendor_payments << VendorPayment.find(id) unless d.available_payments_ids.include? id
      end
    end
  end

  def self.add_order_conditions
    VendorDelivery.find_each do |vd|
      vd.vendor.order_conditions.create! action: 'delivery', event: 'on_create', vendor_delivery_id: vd.id if vd.delivery_case == 'on_create'
      vd.vendor.order_conditions.create! action: 'delivery', event: 'on_pay_success', vendor_delivery_id: vd.id if vd.delivery_case == 'on_pay'

      vd.vendor.order_conditions.create! action: 'reserve', event: 'on_create', vendor_delivery_id: vd.id if vd.reservation_case == 'on_create'
      vd.vendor.order_conditions.create! action: 'reserve', event: 'on_pay_success', vendor_delivery_id: vd.id if vd.reservation_case == 'on_pay'
    end

    VendorPayment.find_each do |vp|
      vp.vendor.order_conditions.create! action: 'delivery', event: 'on_create', vendor_payment_id: vp.id if vp.delivery_case == 'on_create'
      vp.vendor.order_conditions.create! action: 'delivery', event: 'on_pay_success', vendor_payment_id: vp.id if vp.delivery_case == 'on_pay'

      vp.vendor.order_conditions.create! action: 'reserve', event: 'on_create', vendor_payment_id: vp.id if vp.reservation_case == 'on_create'
      vp.vendor.order_conditions.create! action: 'reserve', event: 'on_pay_success', vendor_payment_id: vp.id if vp.reservation_case == 'on_pay'
    end

    WorkflowState.find_each do |ws|
      ws.vendor.order_conditions.create! action: 'delivery', event: 'on_workflow_change', enter_workflow_state_id: ws.id if ws.make_delivery_on_enter?
      ws.vendor.order_conditions.create! action: 'reserve', event: 'on_workflow_change', enter_workflow_state_id: ws.id if ws.make_reserve_on_enter?
    end
  end

  def self.default_workflow_states
    pb = ProgressBar.create total: Vendor.count
    Vendor.find_each do |v|
      pb.increment
      v.send :create_default_workflow_states
    end
  end

  def self.order_workflow_states
    pb = ProgressBar.create total: Order.count
    Order.find_each do |o|
      pb.increment
      finite_state = case o.state.to_sym
                     when :new then :new
                     when :accepted then :in_process
                     when :done then :success
                     when :canceled then :failure
                     else
                       raise "Unknown order state #{o.state}"
                     end
      workflow_state = o.vendor.workflow_states.with_finite_state(finite_state).first
      o.update_column :workflow_state_id, workflow_state.id
    end
  end

  def self.default_dictionaries
    Vendor.find_each do |v|
      if v.dictionaries.empty?
        begin
          DefaultDictionaries.new(v).perform
        rescue => e
          puts e
          Rails.logger.error e
        end
      end
    end
  end

  def self.history_paths_content_type
    HistoryPath.find_each do |hp|
      hp.update_column :content_type, hp.send(:detect_content_type)
    end
  end

  def self.slugs
    ContentPage.find_each do |cp|
      cp.create_slug! path: cp.read_attribute('slug')
    end
  end

  def self.collect_data_to_product_unions
    ProductUnion.find_each(&:touched_product)
  end

  def self.stock_title
    Product.stock_linked.update_all 'stock_title=title, stock_description=description, title=NULL, description=NULL'
    [DictionaryEntity, Dictionary, ProductItem, Category, Property].each do |model|
      model.stock_linked.update_all 'stock_description=description'
    end
  end

  def self.set_product_union_types
    puids = Product.where('product_union_id is not null').group('product_union_id').count.keys
    Product.where(id: puids).update_all type: ProductUnion.name, archived_at: nil
    Product.where.not(type: ProductUnion.name).update_all type: Product.name
  end

  def self.images_geometry
    [LookbookImage, ProductImage, SliderImage].each do |klass|
      klass.find_each do |p|
        p.send :setup_geometry
        p.update_columns width: p.width, height: p.height
      end
    end
  end

  def self.position_to_category_positions
    Category.find_each do |c|
      c.products.update_all ["category_positions = (category_positions || ('?=>' || position)::hstore)", c.id.to_i]
    end
  end

  def self.repair_products_positions
    Category.find_each(&:repair_products_positions)
  end

  def self.create_default_robots
    Vendor.find_each do |vendor|
      VendorRobotsEditor.new(vendor: vendor).set_defaults
    end
  end

  def self.update_robots_sitemap
    Vendor.find_each do |vendor|
      VendorRobotsEditor.new(vendor: vendor).update_sitemap
    end
  end

  def self.sanitize_vendors_h1
    Vendor.find_each do |vendor|
      vendor.update_column :h1, Rails::Html::Sanitizer.full_sanitizer.new.sanitize(vendor.h1)
    end
  end

  def self.move_order_canceling_timeout_to_vendor_payment
    Vendor.find_each do |vendor|
      vendor.vendor_payments.update_all canceling_timeout_minutes: vendor.cancel_pending_orders_period_days.days / 60
    end
  end

  def self.move_custom_filter_properties
    Vendor.find_each do |vendor|
      vendor.properties.where.not(id: vendor.custom_filter_properties_ids).update_all show_in_filter: false
    end
  end

  def self.undo_move_custom_filter_properties
    Vendor.find_each do |vendor|
      vendor.update_column :custom_filter_properties_ids, vendor.properties.where(show_in_filter: true).pluck(:id)
    end
  end

  def self.move_access_tokens_to_member
    AccessToken.find_each do |token|
      token.member.update_column :token, token.token if token.member.present?
    end
    Member.set_tokens
  end

  def self.save_slider_images_to_s3
    SliderImage.where('image_s3 is null').find_each do |slider_image|
      file_path = Rails.root.join('public', slider_image.image.path)
      slider_image.update_attribute :image_s3, File.open(file_path) if File.exist?(file_path)
    end
  end

  def self.clear_broken_cart_items
    CartItem.where('created_at >= ?', Date.current - 1.month).each do |cart_item|
      cart_item.destroy if cart_item.good.selling_by_weight? && !cart_item.weight.present?
    end
  end
end
