class ProductsExportFeature
  include Authority::Abilities
  self.authorizer_name = 'ProductAuthorizer'
end
