class HCBError < StandardError; end

class RaiseHCBErrorMiddleware < Faraday::Middleware
  def on_complete(env)
    raise HCBError, "HCB returned #{env.response.body}" unless env.response.success?
  end
end

Faraday::Response.register_middleware hcb_error: RaiseHCBErrorMiddleware

module HCBService
  class << self
    def base_url
      @hcb_base_url ||= ENV["HCB_BASE_URL"]
    end

    def create_card_grant(email:, amount_cents:, merchant_lock: nil, category_lock: nil, keyword_lock: nil, purpose: nil, pre_authorization_required: false, one_time_use: false, instructions: nil)
      conn.post("organizations/#{@hcb_org_slug}/card_grants", email:, amount_cents:, category_lock:, merchant_lock:, keyword_lock:, purpose:, pre_authorization_required:, one_time_use:, instructions:).body
    end

    def topup_card_grant(hashid:, amount_cents:)
      conn.post("card_grants/#{hashid}/topup", amount_cents:).body
    end

    def rename_transaction(hashid:, new_memo:)
      conn.put("organizations/#{@hcb_org_slug}/transactions/#{hashid}", memo: new_memo).body
    end

    def show_card_grant(hashid:)
      conn.get("card_grants/#{hashid}?expand=balance_cents,disbursements").body
    end

    def update_card_grant(hashid:, merchant_lock: nil, category_lock: nil, keyword_lock: nil, purpose: nil, instructions: nil)
      conn.patch("card_grants/#{hashid}", { merchant_lock:, category_lock:, keyword_lock:, purpose:, instructions: }.compact).body
    end

    def show_stripe_card(hashid:)
      conn.get("cards/#{hashid}").body
    end

    def cancel_card_grant!(hashid:)
      conn.post("card_grants/#{hashid}/cancel").body
    end

    def index_card_grants
      conn.get("organizations/#{@hcb_org_slug}/card_grants").body
    end

    def conn
      hcb_api_token = ENV["HCB_API_TOKEN"]
      @hcb_org_slug = ENV["HCB_ORG_SLUG"]

      raise "missing HCB_BASE_URL >:-O" unless base_url
      raise "missing HCB_API_TOKEN >:-/" unless hcb_api_token
      raise "missing HCB_ORG_SLUG >:-P" unless @hcb_org_slug

      @conn ||= Faraday.new url: "#{base_url}/api/v4/".freeze do |faraday|
        faraday.request :json
        faraday.response :mashify
        faraday.response :json
        faraday.response :hcb_error
        faraday.headers["Authorization"] = "Bearer #{hcb_api_token}".freeze
      end
    end
  end
end
