module Dropbox
  module API
    module HTTP

      TRUSTED_CERT_FILE = File.join(File.dirname(__FILE__), 'trusted-certs.crt')
      HTTPS_PORT = 443

      CERTIFICATE_SIGNATURE_FAILURE = 7
      CERTIFICATE_SUCCESS = 0

      def self.make_query_string(params)
        clean_params(params).collect { |k, v|
          "#{ CGI.escape(k) }=#{ CGI.escape(v) }"
        }.join('&')
      end

      def self.do_http_request(method, host, path, params = {}, headers = {}, body = {}) # :nodoc:
        unless [Net::HTTP::Post, Net::HTTP::Put, Net::HTTP::Get].include?(method)
          fail ArgumentError, "method must one of Net::HTTP::[Post|Put|Get]; got #{ method.inspect }"
        end

        http = Net::HTTP.new(host, HTTPS_PORT)
        set_ssl_settings(http)        

        path_and_params = "/#{ Dropbox::API::API_VERSION }#{ path }?#{ make_query_string(params) }"
        http_request = method.new(path_and_params)
        http_request.initialize_http_header(headers)

        set_http_body(http_request, body)

        # One more header. We use this to better understand how developers are using our SDKs.
        http_request['User-Agent'] =  "OfficialDropboxRubySDK/#{ Dropbox::API::SDK_VERSION }"

        begin
          http.request(http_request)
        rescue OpenSSL::SSL::SSLError => e
          raise DropboxError.new("SSL error connecting to Dropbox.  " +
                  "There may be a problem with the set of certificates in \"#{ TRUSTED_CERT_FILE }\". #{ e.message }")
        end
      end

      private

      def self.set_ssl_settings(http)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file = TRUSTED_CERT_FILE

        # SSL protocol and ciphersuite settings are supported starting with version 1.9
        if RUBY_VERSION >= '1.9'
          http.ssl_version = 'TLSv1'
          http.ciphers = 'ECDHE-RSA-AES256-GCM-SHA384:'\
                'ECDHE-RSA-AES256-SHA384:'\
                'ECDHE-RSA-AES256-SHA:'\
                'ECDHE-RSA-AES128-GCM-SHA256:'\
                'ECDHE-RSA-AES128-SHA256:'\
                'ECDHE-RSA-AES128-SHA:'\
                'ECDHE-RSA-RC4-SHA:'\
                'DHE-RSA-AES256-GCM-SHA384:'\
                'DHE-RSA-AES256-SHA256:'\
                'DHE-RSA-AES256-SHA:'\
                'DHE-RSA-AES128-GCM-SHA256:'\
                'DHE-RSA-AES128-SHA256:'\
                'DHE-RSA-AES128-SHA:'\
                'AES256-GCM-SHA384:'\
                'AES256-SHA256:'\
                'AES256-SHA:'\
                'AES128-GCM-SHA256:'\
                'AES128-SHA256:'\
                'AES128-SHA'
        end

        # Important security note!
        # Some Ruby versions (e.g. the one that ships with OS X) do not raise an exception if certificate validation fails.
        # We therefore have to add a custom callback to ensure that invalid certs are not accepted
        # See https://www.braintreepayments.com/braintrust/sslsocket-verify_mode-doesnt-verify
        # You can comment out this code in case your Ruby version is not vulnerable
        #
        # TODO Comment about this. Error codes are in "man verify"
        http.verify_callback = proc do |preverify_ok, ssl_context|
          success = preverify_ok && ssl_context.error == CERTIFICATE_SUCCESS
          ssl_context.error = CERTIFICATE_SIGNATURE_FAILURE unless success
          success
        end
      end

      def set_http_body(http_request, body)
        if body.is_a?(Hash)
          http_request.body = make_query_string(body)
        elsif body.respond_to?(:read)
          if body.respond_to?(:length)
            http_request['Content-Length'] = body.length.to_s
          elsif body.respond_to?(:stat) && body.stat.respond_to?(:size)
            http_request["Content-Length"] = body.stat.size.to_s
          else
            fail ArgumentError, "Don't know how to handle 'body' (responds to 'read' but not to 'length' or 'stat.size')."
          end
          http_request.body_stream = body
        else
          body = body.to_s
          http_request['Content-Length'] = body.length
          http_request.body = body
        end
      end

      def self.clean_params(params)
        # TODO there isn't a better way to do this?
        new_params = {}
        params.each do |k, v|
          new_params[k.to_s] = v.to_s unless v.nil?
        end
        new_params
      end

    end
  end
end