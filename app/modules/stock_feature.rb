class StockFeature
  include Authority::Abilities
  self.authorizer_name = 'RobotsAuthorizer'
end
