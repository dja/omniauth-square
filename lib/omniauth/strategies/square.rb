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

      uid { raw_info['id'] }

      info do
        prune!(
          :name     => raw_info["name"],
          :email    => raw_info["email"],
          :phone    => (raw_info["business_phone"]||{}).values.join(''),
          :location => (raw_info["business_address"]||{})["locality"]
        )
      end

      extra do
        { :raw_info => raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get('/v1/me').parsed
      end

      protected

      def build_access_token
        parsed_response = fetch_access_token

        parsed_response['expires_at'] = Time.parse(parsed_response['expires_at']).to_i
        parsed_response.merge!(deep_symbolize(options.auth_token_params))

        connect_client = client.dup
        connect_client.site = options.client_options.connect_site
        ::OAuth2::AccessToken.from_hash(connect_client, parsed_response)
      end

      private

      def fetch_access_token
        opts     = access_token_request_payload
        response = client.request(client.options[:token_method], client.token_url, opts)
        parsed   = response.parsed
        error    = ::OAuth2::Error.new(response)
        fail(error) if opts[:raise_errors] && !(parsed.is_a?(Hash) && parsed['access_token'])
        parsed
      end

      def access_token_request_payload
        params = {
          :code         => request.params['code'],
          :redirect_uri => callback_url
        }

        params.merge! token_params.to_hash(:symbolize_keys => true)

        opts = {
          :raise_errors => params.delete(:raise_errors),
          :parse        => params.delete(:parse),
          :headers      => {'Content-Type' => 'application/x-www-form-urlencoded'}
        }

        headers     = params.delete(:headers)
        opts[:body] = params
        opts[:headers].merge!(headers) if headers
        opts
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
