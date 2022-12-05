class YmlFeature
  include Authority::Abilities
  self.authorizer_name = 'YmlAuthorizer'
end
