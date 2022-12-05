class Aramex::Operation::ShipmentTracker < Aramex::Operation::Base
  attribute :order_delivery, OrderDelivery

  WSDL_HOST = 'https://ws.aramex.net/ShippingAPI.V2/Tracking/Service_1_0.svc?singleWsdl'.freeze
  TEST_WSDL_HOST = 'https://ws.dev.aramex.net/ShippingAPI.V2/Tracking/Service_1_0.svc?singleWsdl'.freeze

  def initialize(order_delivery:)
    super order_delivery: order_delivery, is_test: order_delivery.delivery_type.aramex_is_test
  end

  def perform
    res = shipment_track.body

    raise Aramex::ResponseError.new res if res[:shipment_tracking_response][:has_errors]

    tracking_result = res[:shipment_tracking_response][:tracking_results][:key_value_ofstring_array_of_tracking_resultm_f_akxlp_y][:value][:tracking_result]

    tracking_result.is_a?(Array) ? tracking_result.first : tracking_result
  end

  private

  delegate :delivery_type, to: :order_delivery

  def shipment_track
    client.call(:track_shipments, message: data)
  end

  def data
    {
      ClientInfo: client_info,
      Transaction: Aramex::Entity::Transaction.new(Reference1: '1', Reference2: '', Reference3: '', Reference4: '', Reference5: '').to_h,
      Shipments: { 'ins0:string': [shipment] },
      GetLasTrackingUpdateOnly: true,
    }
  end

  def shipment
    order_delivery.tracking_id.to_s
  end
end

# {:shipment_tracking_response=>
#   {:transaction=>{:reference1=>"1", :reference2=>nil, :reference3=>nil, :reference4=>nil, :reference5=>nil, :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"},
#    :notifications=>{:"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"},
#    :has_errors=>false,
#    :tracking_results=>
#     {:key_value_ofstring_array_of_tracking_resultm_f_akxlp_y=>
#       {:key=>"1757103880",
#        :value=>
#         {:tracking_result=>
#           {:waybill_number=>"1757103880",
#            :update_code=>"SH014",
#            :update_description=>"Record created.",
#            :update_date_time=>123,
#            :update_location=>"Moscow, Russia",
#            :comments=>"0.5,0.5,KG <DIM><WF>6000</WF><P>1</P><L>10</L><W>10</W><H>10</H><WU>CM</WU><GW>0.5</GW><VW>0.166666666666667</VW><CW>0.5</CW></DIM>",
#            :problem_code=>nil,
#            :gross_weight=>"0.5",
#            :chargeable_weight=>"0.5",
#            :weight_unit=>"KG"}}},
#      :"@xmlns:a"=>"http://schemas.microsoft.com/2003/10/Serialization/Arrays",
#      :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"},
#    :non_existing_waybills=>{:"@xmlns:a"=>"http://schemas.microsoft.com/2003/10/Serialization/Arrays", :"@xmlns:i"=>"http://www.w3.org/2001/XMLSchema-instance"},
#    :@xmlns=>"http://ws.aramex.net/ShippingAPI/v1/"}}
