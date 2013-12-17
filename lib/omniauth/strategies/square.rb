require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Square < OmniAuth::Strategies::OAuth2

      option :client_options, {
        :site => 'https://squareup.com/',
        :authorize_url => 'https://squareup.com/oauth2/authorize',
        :token_url => 'https://squareup.com/oauth2/token'
      }

      option :access_token_options, {
        mode: :query,
        header_format: 'OAuth %s'
      }

      option :provider_ignores_state, true


      def request_phase
        options[:authorize_params] = {
          request_type:  'code',
          session:        true
        }

        super
      end

      uid { raw_info['id'] }

      info do
        prune!({
          "name" => raw_info["name"],
          "email" => raw_info["email"],
          "country_code" => raw_info["country_code"],
          "language_code" => raw_info["language_code"]
        })
      end

      credentials do
        hash = {'token' => access_token.token}
        hash.merge!('token_type' => access_token.token_type)
        hash.merge!('expires_at' => access_token.expires_at) if access_token.expires_at?
        prune!(hash)
      end

      def raw_info
        unless skip_info?
          @raw_info ||= access_token.get('https://connect.squareup.com/v1/me').parsed
        else
          {}
        end
      end

      def authorize_params
        super.tap do |params|
          %w[state].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]

              # to support omniauth-oauth2's auto csrf protection
              session['omniauth.state'] = params[:state] if v == 'state'
            end
          end

        end
      end

    private
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