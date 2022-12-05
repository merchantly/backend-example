class IntegrationsFeature
  include Authority::Abilities
  self.authorizer_name = 'VendorAuthorizer'
end
