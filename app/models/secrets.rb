class SecretsClass < Hashie::Mash
  disable_warnings
end

Secrets = SecretsClass.new Rails.application.secrets
