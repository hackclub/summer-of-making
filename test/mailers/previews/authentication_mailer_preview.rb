# Preview all emails at http://localhost:3000/rails/mailers/authentication_mailer
class AuthenticationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/authentication_mailer/magic_link
  def magic_link
    user = User.first || User.new(
      email: "test@hackclub.com",
      display_name: "Test User",
      slack_id: "U123456"
    )
    magic_link = MagicLink.new(user: user, token: "abcdef123456789")
    AuthenticationMailer.magic_link(user, magic_link)
  end
end
