class MoyskladFeature
  include Authority::Abilities
  self.authorizer_name = 'MoyskladAuthorizer'
end
