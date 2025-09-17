module SecretThirdThing
  class << self
    def tab_title = spooky_data[:tab_title]
    def tab_icon = spooky_data[:tab_icon]
    def base_url = ENV["STT_BASE_URL"] || spooky_data[:base_url]

    def dejigimaflip(data) = verifier.generate(data)

    private

    def spooky_data
      @data ||= Rails.application.credentials.dig(:secret_third_thing) || {}
    end

    def shared_secret = spooky_data[:shared_secret]
    def verifier = ActiveSupport::MessageVerifier.new shared_secret
  end
end
