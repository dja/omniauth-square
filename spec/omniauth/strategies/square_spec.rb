require 'spec_helper'

describe OmniAuth::Strategies::Square do
  before :each do
    @request = double('Request', :scheme => '', :url => '')
    @request.stub(:params) { {} }
  end

  subject do
    OmniAuth::Strategies::Square.new(nil, @options || {}).tap do |strategy|
      strategy.stub(:request) { @request }
    end
  end

  describe '#client' do
    it 'has correct Square site' do
      subject.client.site.should eq('https://squareup.com/')
    end

    it 'has correct authorize url' do
      subject.client.options[:authorize_url].should eq('/oauth2/authorize')
    end

    it 'has correct token url' do
      subject.client.options[:token_url].should eq('/oauth2/token')
    end
  end

  describe '#info' do
    before :each do
      @raw_info = {
        "merchant" => [{
          "id" => "JGHJ0343",
          "business_name" => "Foobar Sports",
          "country" => "US",
          "language_code" => "en-US",
          "currency" => "USD",
          "status" => "ACTIVE",
          "main_location_id" => "DDM555V5KQPNS"
        }]
      }

      subject.stub(:raw_info) { @raw_info }
    end

    context 'when data is present in raw info' do
      it 'returns the name' do
        subject.info[:name].should eq('Foobar Sports')
      end

      it 'returns raw info' do
        subject.extra[:raw_info]['merchant'][0]['business_name'].should eq("Foobar Sports")
      end
    end
  end

  describe '#credentials' do
    before :each do
      @access_token = double('OAuth2::AccessToken')
      @access_token.stub(:token)
      @access_token.stub(:expires?)
      @access_token.stub(:expires_at)
      @access_token.stub(:refresh_token)
      subject.stub(:access_token) { @access_token }
    end

    it 'returns a Hash' do
      subject.credentials.should be_a(Hash)
    end

    it 'returns the token' do
      @access_token.stub(:token) { '123' }
      subject.credentials['token'].should eq('123')
    end

    it 'returns the expiry status' do
      @access_token.stub(:expires?) { true }
      subject.credentials['expires'].should eq(true)

      @access_token.stub(:expires?) { false }
      subject.credentials['expires'].should eq(false)
    end

    it 'returns the refresh token and expiry time when expiring' do
      ten_mins_from_now = (Time.now + 360).to_i
      @access_token.stub(:expires?) { true }
      @access_token.stub(:refresh_token) { '321' }
      @access_token.stub(:expires_at) { ten_mins_from_now }
      subject.credentials['refresh_token'].should eq('321')
      subject.credentials['expires_at'].should eq(ten_mins_from_now)
    end

    it 'does not return the refresh token when it is nil and expiring' do
      @access_token.stub(:expires?) { true }
      @access_token.stub(:refresh_token) { nil }
      subject.credentials['refresh_token'].should be_nil
      subject.credentials.should_not have_key('refresh_token')
    end

    it 'does not return the refresh token when not expiring' do
      @access_token.stub(:expires?) { false }
      @access_token.stub(:refresh_token) { 'XXX' }
      subject.credentials['refresh_token'].should be_nil
      subject.credentials.should_not have_key('refresh_token')
    end
  end
end