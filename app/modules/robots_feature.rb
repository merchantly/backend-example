class RobotsFeature
  include Authority::Abilities
  self.authorizer_name = 'RobotsAuthorizer'
end
