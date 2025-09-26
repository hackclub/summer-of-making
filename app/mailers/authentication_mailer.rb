class AuthenticationMailer < ApplicationMailer
  def magic_link(user, magic_link)
    @user = user
    @magic_link = magic_link
    @magic_link_url = magic_link.secret_url(request_host)

    mail(
      to: @user.email,
      subject: "Are you signing into Summer of Making?"
    )
  end

  private

  def request_host
    Rails.env.production? ? "summer.hackclub.com" : "localhost:3000"
  end
end
