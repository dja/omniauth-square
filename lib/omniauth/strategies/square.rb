require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Square < OmniAuth::Strategies::OAuth2

      option :client_options, {
        :site          => 'https://squareup.com/',
        :authorize_url => 'https://squareup.com/oauth2/authorize',
        :token_url     => 'https://squareup.com/oauth2/token'
      }

      option :access_token_options, {
        :mode          => :query,
        :header_format => 'OAuth %s'
      }

      option :token_params, {:parse => :json}

      option :provider_ignores_state, true

      def request_phase
        options[:authorize_params] = {
          :request_type => 'code',
          :session      => true
        }

        super
      end

      uid { raw_info['id'] }

      info do
        prune!('name' => raw_info["name"], 'email' => raw_info["email"])
      end

      extra do
        prune! skip_info? ? {} : {'raw_info' => raw_info}
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

      protected

      def build_access_token
        parsed = fetch_access_token

        parsed['expires_at'] = Time.parse(parsed['expires_at']).to_i
        parsed.merge!(deep_symbolize(options.auth_token_params))

        ::OAuth2::AccessToken.from_hash(client, parsed)
      end

      private

      def fetch_access_token
        params = {
          :grant_type   => 'authorization_code',
          :code         => request.params['code'],
          :redirect_uri => callback_url
        }

        params.merge! client.auth_code.client_params
        params.merge! token_params.to_hash(:symbolize_keys => true)

        opts = {:raise_errors => params.delete(:raise_errors), :parse => params.delete(:parse)}
        headers        = params.delete(:headers)
        opts[:body]    = params
        opts[:headers] = {'Content-Type' => 'application/x-www-form-urlencoded'}
        opts[:headers].merge!(headers) if headers

        response = client.request(client.options[:token_method], client.token_url, opts)

        error = ::OAuth2::Error.new(response)
        fail(error) if opts[:raise_errors] && !(response.parsed.is_a?(Hash) && response.parsed['access_token'])

        response.parsed
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
