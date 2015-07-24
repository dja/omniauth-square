require 'spec_helper'

describe OmniAuth::Strategies::Square do
  before :each do
    @request = double('Request', :scheme => '', :url => '', :params => {}, :cookies => {}, :env => {})
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
        "id" => "JGHJ0343",
        "name" => "Dave Davis",
        "email" => "dave@example.com",
        "country_code" => "US",
        "language_code" => "en-US",
        "business_name" => "Dave's Milkshakes",
        "business_address" => {
          "address_line_1" => "1455 Market St",
          "locality" => "San Francisco",
          "administrative_district_level_1" => "CA",
          "postal_code" => "94103"
        },
        "business_phone" => {
          "calling_code" => "+1",
          "number" => "4155551234"
        },
        "business_type" => "restaurants"
      }

      subject.stub(:raw_info) { @raw_info }
    end

    context 'when data is present in raw info' do
      it 'returns the name' do
        subject.info[:name].should eq('Dave Davis')
      end

      it 'returns the email' do
        subject.info[:email].should eq('dave@example.com')
      end

      it 'returns the phone number' do
        subject.info[:phone].should eq('+14155551234')
      end

      it 'returns the user location' do
        subject.info[:location].should eq('San Francisco')
      end

      it 'sets the location blank if business_address isnt provided' do
        @raw_info.delete('business_address')
        subject.info[:location].should be_nil
      end

      it 'returns raw info' do
        subject.extra[:raw_info]['business_name'].should eq("Dave's Milkshakes")
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

  describe '#build_access_token' do
    let(:token_hash) do
      {'expires_at' => Time.now.iso8601, 'access_token' => '1111111'}
    end

    before do
      subject.stub(:fetch_access_token).and_return(token_hash.dup)
      @token = subject.send :build_access_token
    end

    it 'converts iso8601 expires_at to an integer' do
      expires = Time.parse(token_hash['expires_at']).to_i
      expect(@token.expires_at).to eq(expires)
    end

    it 'changes the clients site' do
      expect(@token.client.site).to eq('https://connect.squareup.com')
    end
  end

  describe '#request_phase' do
    before do
      @request.stub(:params).and_return('plan_id' => 'test_plan_id')
      subject.stub(:old_request_phase).and_return(:something)
    end

    it 'adds `plan_id` parameter to `authorize_params`' do
      expect { subject.request_phase }.to change { subject.options.authorize_params.plan_id }.
        from(nil).to('test_plan_id')
    end
  end

  describe '#access_token_request_payload' do
    before do
      @request.stub(:params).and_return('code' => '11111')
      subject.stub(:callback_url).and_return('http://example.com')
    end

    let!(:payload) { subject.send(:access_token_request_payload) }

    it 'sets the Content-Type header' do
      expect(payload[:headers]['Content-Type']).to eq('application/x-www-form-urlencoded')
    end

    it 'sets the redirect_uri' do
      expect(payload[:body][:redirect_uri]).to eq('http://example.com')
    end

    it 'sets the authorization code' do
      expect(payload[:body][:code]).to eq('11111')
    end
  end
end
