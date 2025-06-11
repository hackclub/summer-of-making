# frozen_string_literal: true

class IdentityVaultService
  class << self
    def authorize_url(redirect_uri, sneaky_params = nil)
      params = {
        client_id: Rails.application.credentials.dig(:identity_vault, :client_id),
        redirect_uri:,
        response_type: "code",
        scope: "basic_info address",
        stash_data: encode_sneaky_params(sneaky_params)
      }.compact_blank

      "#{Rails.application.credentials.dig(:identity_vault, :host)}oauth/authorize?#{params.to_query}"
    end

    def exchange_token(redirect_uri, code)
      conn.post("/oauth/token") do |req|
        req.body = {
          client_id: Rails.application.credentials.dig(:identity_vault, :client_id),
          client_secret: Rails.application.credentials.dig(:identity_vault, :client_secret),
          redirect_uri:,
          code:,
          grant_type: "authorization_code"
        }
      end.body
    end

    def me(user_token)
      raise ArgumentError, "user_token is required" unless user_token

      conn.get("/api/v1/me", nil, {
                 Authorization: "Bearer #{user_token}"
               }).body
    end

    def get_identity(identity_id)
      conn.get("/api/v1/identities/#{identity_id}").body
    end

    def build_address_creation_url(sneaky_params = nil)
      params = {
        stash_data: encode_sneaky_params(sneaky_params)
      }.compact_blank

      identity_vault_host = Rails.application.credentials.dig(:identity_vault, :host)
      "#{identity_vault_host}addresses/program_create_address?#{params.to_query}"
    end



    private

    def conn
      @conn ||= Faraday.new(
        url: Rails.application.credentials.dig(:identity_vault, :host),
        headers: {
          "Authorization" => "Bearer #{Rails.application.credentials.dig(:identity_vault, :global_program_key)}"
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
