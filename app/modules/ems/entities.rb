module EMS::Entities
  class Track
    include HappyMapper
    tag :track

    attribute :id,    Integer
    attribute :date,  String
    attribute :time,  String
    attribute :geo,   String
    attribute :description, String, xpath: '@event'

    def datetime
      Time.zone.parse "#{date} #{time}"
    end
  end

  class Item
    include HappyMapper
    tag :item

    element :routeStartLoc,  String, xpath: 'routeStartLoc/@value'
    element :routeStartTime, String, xpath: 'routeStartTime/@value'
    element :routeEndLoc,    String, xpath: 'routeEndLoc/@value'
    element :routeEndTime,   String, xpath: 'routeEndTime/@value'
    element :transitTime,    String, xpath: 'transitTime/@value'
    element :signedFor,      String, xpath: 'signedFor/@value'
    element :delivered,      String, xpath: 'delivered/@value'

    has_many :tracks, Track, xpath: 'tracking'
  end

  class Response
    include HappyMapper
    tag :response
    has_one :count, Integer, xpath: 'track_number/count'
    has_many :items, Item, xpath: 'track_number/items'

    def persisted?
      count.positive?
    end
  end
end

# <response>
#   <track_number id="EA338712012RU" carrier="EMS">
#     <count>1</count>
#     <items>
#       <item id="1">
#         <routeStartLoc value="Видное EMS ППС-5"/>
#         <routeStartTime value="12/08/2014 17:00"/>
#         <routeEndLoc value="Урюпинск 3"/>
#         <routeEndTime value="18/08/2014 13:40"/>
#         <transitTime value=""/>
#         <signedFor value=""/>
#         <delivered value="yes"/>
#         <tracking>
#           <track id="0" date="12/08/2014" time="17:00" geo="Видное EMS ППС-5, 142705" event="Приём. Единичный"/>
#           <track id="1" date="12/08/2014" time="21:55" geo="Видное EMS ППС-5, 142705" event="Обработка. Покинуло сортировочный центр"/>
#           <track id="2" date="13/08/2014" time="16:55" geo="Москва EMS СЦ цех Магистральной Сортировки Уо, 130214" event="Обработка. Сортировка"/>
#           <track id="3" date="14/08/2014" time="13:35" geo="Москва EMS СЦ цех Магистральной Сортировки Уо, 130214" event="Обработка. Покинуло сортировочный центр"/>
#           <track id="4" date="16/08/2014" time="10:15" geo="Урюпинск 3, 403113" event="Обработка. Прибыло в место вручения"/>
#           <track id="5" date="16/08/2014" time="13:30" geo="Урюпинск 3, 403113" event="Неудачная попытка вручения. Временное отсутствие адресата"/>
#           <track id="6" date="20/08/2014" time="09:50" geo="Волгоград МСЦ УОСП, 400964" event="Обработка. Покинуло сортировочный центр"/>
#           <track id="7" date="18/08/2014" time="13:40" geo="Урюпинск 3, 403113" event="Вручение. Вручение адресату"/>
#         </tracking>
#       </item>
#     </items>
#   </track_number>
# </response>
