require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Square < OmniAuth::Strategies::OAuth2
      option :client_options, {
        :site          => 'https://squareup.com/',
        :connect_site  => 'https://connect.squareup.com',
        :authorize_url => '/oauth2/authorize',
        :token_url     => '/oauth2/token'
      }

      uid { raw_info["merchant"][0]["id"] }

      info do
        prune!(
          :name     => raw_info["merchant"][0]["business_name"],
          :country  => raw_info["merchant"][0]["country"]
        )
      end

      extra do
        { :raw_info => raw_info }
      end

      def build_access_token
        connect_client = client.dup
        connect_client.site = options.client_options.connect_site
        auth_params = {
          :redirect_uri => callback_url,
          :client_id => options.client_id,
          :client_secret => options.client_secret,
          :grant_type => "authorization_code"
        }.merge(token_params.to_hash(:symbolize_keys => true))
        connect_client.auth_code.get_token(
          request.params["code"],
          auth_params.merge(
            token_params.to_hash(:symbolize_keys => true)
          ),
          deep_symbolize(options.auth_token_params)
        )
      end

      private

      def raw_info
        @raw_info ||= access_token.get('/v2/merchants').parsed
      end

      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end
    end
  end
end

OmniAuth.config.add_camelization 'square', 'Square'