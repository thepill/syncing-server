module SyncEngine
  module JwtHelper
    require 'jwt'

    def self.encode(payload)
      JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
    end

    def self.decode(token)
      HashWithIndifferentAccess.new(JWT.decode(token, Rails.application.secrets.secret_key_base, true, algorithm: 'HS256')[0])
    rescue StandardError => e
      puts e
      nil
    end
  end
end
