require 'spec_helper'

describe Dropbox::API::WebAuth do

  before(:each) do
    @session = {}
    app_info = Dropbox::API::AppInfo.new('app_key', 'app_secret')
    @auth = Dropbox::API::WebAuth.new(app_info, 'redirect.com', @session, :csrf_token, 'client_test')
  end

  describe '#initialize' do
    it_behaves_like 'OAuth2' do
      it_behaves_like '#oauth2_init' do
        let(:auth) { @auth }
      end
    end

    it 'requires a redirect_uri' do
      app_info = Dropbox::API::AppInfo.new('app_key', 'app_secret')
      expect {
        auth = Dropbox::API::WebAuth.new(app_info, nil, nil)
      }.to raise_error(ArgumentError, /redirect_uri/)
    end
  end

  describe '#start' do
    it_behaves_like 'OAuth2' do
      it_behaves_like '#get_authorize_url' do
        let(:auth) { @auth }
      end
    end

    it 'saves a URL-safe CSRF token' do
      @auth.start
      expect(@session[:csrf_token]).to match(/[-_A-Za-z0-9]{#{ Dropbox::API::WebAuth::CSRF_TOKEN_LENGTH }}/)
    end

    it 'saves the same CSRF token in session and query parameters' do
      url = @auth.start
      expect(url).to include(@session[:csrf_token])
    end

    it 'saves state parameter' do
      expect(@auth.start('mystate')).to match(/state=[-_A-Za-z0-9]{#{ Dropbox::API::WebAuth::CSRF_TOKEN_LENGTH }}|mystate/)
    end

    it 'specifies redirect_uri parameter' do
      expect(@auth.start()).to include('redirect_uri=redirect.com')
    end

    it 'specifies force_reapprove parameter only if true' do
      expect(@auth.start(nil)).not_to include('force_reapprove')
      expect(@auth.start(nil, true)).to include('force_reapprove=true')
    end
  end

  describe '#finish' do
    it_behaves_like 'OAuth2' do
      it_behaves_like '#get_token' do
        let(:auth) { @auth }
      end
    end

    it 'requires state parameter' do
      expect {
        @auth.finish({ 'code' => 'mycode' })
      }.to raise_error(Dropbox::API::WebAuth::BadRequestError, /state/)
    end

    it 'requires code xor error parameter' do
      expect {
        @auth.finish({ 'state' => 'mystate' })
      }.to raise_error(Dropbox::API::WebAuth::BadRequestError, /code.*error|error.*code/)
      expect {
        @auth.finish({ 'state' => 'mystate', 'code' => 'mycode', 'error' => 'myerror'})
      }.to raise_error(Dropbox::API::WebAuth::BadRequestError, /code.*error|error.*code/)
    end

    it 'checks that CSRF token is in session' do
      expect {
        @auth.finish({ 'state' => 'mystate', 'code' => 'mycode' })
      }.to raise_error(Dropbox::API::WebAuth::BadStateError, /CSRF token/)
    end

    it 'checks CSRF token length' do
      @session[:csrf_token] = ''
      expect {
        @auth.finish({ 'state' => '', 'code' => 'mycode' })
      }.to raise_error(RuntimeError)
    end

    it 'checks that CSRF token is the same' do
      @session[:csrf_token] = 't' * Dropbox::API::WebAuth::CSRF_TOKEN_LENGTH
      expect {
        @auth.finish({ 'state' => 'n' * Dropbox::API::WebAuth::CSRF_TOKEN_LENGTH, 'code' => 'mycode' })
      }.to raise_error(Dropbox::API::WebAuth::CsrfError)
    end

    it 'extracts user-provided state' do
      @session[:csrf_token] = 't' * Dropbox::API::WebAuth::CSRF_TOKEN_LENGTH
      stub_body = Oj.dump({
        'token_type' => 'bearer',
        'access_token' => 'returned_access_token',
        'uid' => 'returned_uid'
      })
      params = {
         'state' => "#{ 't' * Dropbox::API::WebAuth::CSRF_TOKEN_LENGTH }|mystate",
         'code' => 'mycode'
      }
      stub_request(:any, "https://app_key:app_secret@#{ Dropbox::API::API_SERVER }/#{ Dropbox::API::API_VERSION }/oauth2/token")
          .with(query: {code: 'mycode', grant_type: 'authorization_code', redirect_uri: 'redirect.com'})
          .to_return(status: 200, body: stub_body)
      access_token, uid, state = @auth.finish(params)
      expect(state).to eq('mystate')
      expect(@session[:csrf_token]).to be_nil
      expect(access_token).to eq('returned_access_token')
      expect(uid).to eq('returned_uid')
    end

    it 'throws NotApprovedError if user denies' do
      @session[:csrf_token] = 't' * Dropbox::API::WebAuth::CSRF_TOKEN_LENGTH
      params = {
        'state' => "#{ 't' * Dropbox::API::WebAuth::CSRF_TOKEN_LENGTH }",
        'error' => 'access_denied',
        'error_description' => 'description'
      }
      expect {
        @auth.finish(params)
      }.to raise_error(Dropbox::API::WebAuth::NotApprovedError, /description/)
    end

    it 'throws ProviderError if other error occurs' do
      @session[:csrf_token] = 't' * Dropbox::API::WebAuth::CSRF_TOKEN_LENGTH
      params = {
        'state' => "#{ 't' * Dropbox::API::WebAuth::CSRF_TOKEN_LENGTH }",
        'error' => 'other message',
        'error_description' => 'description'
      }
      expect {
        @auth.finish(params)
      }.to raise_error(Dropbox::API::WebAuth::ProviderError, /description/)
    end

  end
end