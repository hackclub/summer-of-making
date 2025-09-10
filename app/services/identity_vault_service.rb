# frozen_string_literal: true

class IdentityVaultService
  class << self
    def env
      Rails.env.production? ? :prod : :staging
    end

    def host
      @host ||= {
        staging: "https://idv-staging.a.hackclub.dev/",
        prod: "https://identity.hackclub.com/"
      }[env]
    end

    def creds
      Rails.application.credentials.dig(:identity_vault, env)
    end

    def authorize_url(redirect_uri, sneaky_params = nil)
      params = {
        client_id: creds[:client_id],
        redirect_uri:,
        response_type: "code",
        scope: "basic_info address",
        stash_data: encode_sneaky_params(sneaky_params)
      }.compact_blank

      "#{host}oauth/authorize?#{params.to_query}"
    end

    def exchange_token(redirect_uri, code)
      can_retry do
        conn.post("/oauth/token") do |req|
          req.body = {
            client_id: creds[:client_id],
            client_secret: creds[:client_secret],
            redirect_uri:,
            code:,
            grant_type: "authorization_code"
          }
        end.body
      end
    end

    def me(user_token)
      raise ArgumentError, "user_token is required" unless user_token

      can_retry do
        conn.get("/api/v1/me", nil, {
                   Authorization: "Bearer #{user_token}"
                 }).body
      end
    end

    def get_identity(identity_id)
      can_retry do
        conn.get("/api/v1/identities/#{identity_id}").body
      end
    end

    def set_slack_id(identity_id, slack_id)
      can_retry do
        conn.post("api/v1/identities/#{identity_id}/set_slack_id", { slack_id: }).body
      end
    end

    def build_address_creation_url(sneaky_params = nil)
      params = {
        stash_data: encode_sneaky_params(sneaky_params)
      }.compact_blank

      "#{host}addresses/program_create_address?#{params.to_query}"
    end

    private

    def can_retry(max = 3)
      retries = 0
      begin
        yield
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError, SocketError => e
        retries += 1
        if retries <= max
          Rails.logger.warn "idv poll failed (try #{retries}/#{max + 1}): #{e.message}"
          sleep(0.5 * retries)
          retry
        else
          Rails.logger.error "idv poll failed after retry: #{e.message}"
          Honeybadger.notify(e)
          raise
        end
      end
    end

    def conn
      @conn ||= Faraday.new(
        url: host,
        headers: {
          "Authorization" => "Bearer #{creds[:global_program_key]}"
        }
      ) do |f|
        f.request :json
        f.response :json, parser_options: { symbolize_names: true }
        f.response :raise_error
      end
    end

    def encode_sneaky_params(params)
      return nil unless params

      Base64.urlsafe_encode64(LZString::UTF16.compress(params.to_json))
    end
  end
end
