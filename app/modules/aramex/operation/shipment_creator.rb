class Aramex::Operation::ShipmentCreator < Aramex::Operation::Base
  WSDL_HOST = 'https://ws.aramex.net/ShippingAPI.V2/Shipping/Service_1_0.svc?singleWsdl'.freeze
  TEST_WSDL_HOST = 'https://ws.dev.aramex.net/ShippingAPI.V2/Shipping/Service_1_0.svc?singleWsdl'.freeze

  attribute :order, Order

  def initialize(order:)
    super order: order, is_test: order.delivery_type.aramex_is_test
  end

  def perform
    res = create_shipments.body

    raise Aramex::ResponseError.new res if res[:shipment_creation_response][:has_errors]

    id = res[:shipment_creation_response][:shipments][:processed_shipment][:id]

    order.order_delivery.update! external_id: id, error: nil
  rescue StandardError => e
    Aramex.logger.error e
    order.order_delivery.cancel_with_error!(e.to_s)
    order.vendor.bells_handler.add_error e, error: e.to_s if e.is_a?(Aramex::ResponseError)

    Bugsnag.notify e, metaData: { res: res }
  end

  private

  delegate :delivery_type, to: :order

  def create_shipments
    client.call(:create_shipments, message: data)
  end

  def data
    {
      ClientInfo: client_info,
      Shipments: [shipment],
      Transaction: Aramex::Entity::Transaction.new(Reference1: '', Reference2: '', Reference3: '', Reference4: '', Reference5: '').to_h,
      LabelInfo: label_info
    }
  end

  def shipment
    {
      Shipment: {
        Shipper: {
          Reference1: 'ref 1',
          Reference2: 'ref 2',
          AccountNumber: client_info[:AccountNumber],
          PartyAddress: address(address: delivery_type.shipper_address, city: delivery_type.shipper_city, postal_code: delivery_type.shipper_postal_code, country_code: delivery_type.shipper_country_code),
          Contact: contact(name: delivery_type.shipper_name, phone: delivery_type.shipper_phone, email: delivery_type.shipper_email)
        },
        Consignee: {
          Reference1: 'ref 3',
          Reference2: 'ref 4',
          PartyAddress: address(address: order.address, city: order.city_title, postal_code: order.postal_code, country_code: order.country_code),
          Contact: contact(name: order.name, phone: order.phone, email: order.email)
        },
        ShippingDateTime: Time.zone.now.iso8601,
        DueDate: Time.zone.now.iso8601,
        Comments: '',
        PickupLocation: '',
        Details: details
      }
    }
  end

  def details
    {
      Dimensions: {
        Length: delivery_type.default_length,
        Width: delivery_type.default_width,
        Height: delivery_type.default_height,
        Unit: 'cm',
      },

      ActualWeight: {
        Unit: 'Kg', # KG or LB
        Value: (delivery_type.default_weight_gr.to_f / 1000)
      },

      ChargeableWeight: {
        Unit: 'Kg',
        Value: (delivery_type.default_weight_gr.to_f / 1000)
      },

      DescriptionOfGoods: 'Docs',
      GoodsOriginCountry: delivery_type.shipper_country_code,
      NumberOfPieces: 1,
      ProductGroup: product_group, # EXP = Express, DOM = Domestic
      ProductType: product_type, # Appendix A –Product Types
      PaymentType: 'P', # P, C, 3
      PaymentOptions: '',
      CustomsValueAmount: {
        CurrencyCode: order.currency.iso_code,
        Value: order.total_with_delivery_price.to_f
      },

      CashOnDeliveryAmount: {
        CurrencyCode: '',
        Value: 0
      },
      InsuranceAmount: {
        CurrencyCode: '',
        Value: 0
      },
      CashAdditionalAmount: {
        CurrencyCode: '',
        Value: 0
      },

      CashAdditionalAmountDescription: '',
      CollectAmount: {
        CurrencyCode: '',
        Value: 0
      },
      Services: '',
      Items: [] # items
    }
  end

  def product_group
    if delivery_type.shipper_country_code == order.country_code
      'DOM'
    else
      'EXP'
    end
  end

  def product_type
    if delivery_type.shipper_country_code == order.country_code
      'CDS'
    else
      'EPX'
    end
  end

  # def items
  #   [
  #     {
  #       PackageType: 'Box',
  #       Quantity: 1,
  #       Weight: {
  #         Unit: 'Kg',
  #         Value: 0.5
  #       },
  #       Comments: 'Docs',
  #       Reference: ''
  #     }
  #   ]
  # end

  def label_info
    {
      ReportID: '9201',
      ReportType: 'URL'
    }
  end
end

# {:shipment_creation_response=>
#   {:transaction=>nil,
#    :notifications=>{:"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"},
#    :has_errors=>false,
#    :shipments=>
#     {:processed_shipment=>
#       {:id=>"1757103880",
#        :reference1=>nil,
#        :reference2=>nil,
#        :reference3=>nil,
#        :foreign_hawb=>nil,
#        :has_errors=>false,
#        :notifications=>nil,
#        :shipment_label=>{:label_url=>"http://www.sandbox.aramex.com/content/rpt_cache/241c2c666e9348919b6f7277a5887366.pdf", :label_file_contents=>nil},
#        :shipment_details=>
#         {:origin=>"MOW",
#          :destination=>"MOW",
#          :chargeable_weight=>{:unit=>"KG", :value=>"0.5"},
#          :description_of_goods=>"Docs",
#          :goods_origin_country=>"Jo",
#          :number_of_pieces=>"1",
#          :product_group=>"EXP",
#          :product_type=>"PDX",
#          :payment_type=>"P",
#          :payment_options=>nil,
#          :customs_value_amount=>{:currency_code=>nil, :value=>"0"},
#          :cash_on_delivery_amount=>{:currency_code=>nil, :value=>"0"},
#   :collect_amount=>{:currency_code=>nil, :value=>"0"},
#       :services=>nil},
#     :shipment_attachments=>nil},
#   :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"},
# :@xmlns=>"http://ws.aramex.net/ShippingAPI/v1/"}}
