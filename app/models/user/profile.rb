# == Schema Information
#
# Table name: user_profiles
#
#  id                   :bigint           not null, primary key
#  balloon_color        :string
#  bio                  :text
#  custom_css           :text
#  hide_from_logged_out :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  user_id              :bigint           not null
#
# Indexes
#
#  index_user_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class User::Profile < ApplicationRecord
  belongs_to :user

  validates :bio, length: { maximum: 1000 }, allow_blank: true
  validates :custom_css, length: { maximum: 10_000 }, allow_blank: true
  validate :custom_css_requires_badge
  validate :fucking_xss
  validates_format_of :balloon_color, with: /\A#(?:\h{3}){1,2}\z/, allow_blank: true

  before_save :clean_css

  private

  def custom_css_requires_badge
    return if custom_css.blank?

    unless user.has_badge?(:graphic_design_is_my_passion)
      errors.add(:custom_css, "requires the 'Graphic Design is My Passion' badge")
    end
  end

  def fucking_xss
    return if custom_css.blank?

    css = custom_css.downcase
    bad = [ "</style>", "<script", "javascript:", "@import", "/*</style>", "*/<", "/*<" ]

    bad.each do |pattern|
      if css.include?(pattern)
        errors.add(:custom_css, "nice try jackwagon")
        return
      end
    end

    if css.match?(/\/\*.*<.*\*\//m) || css.match?(/<[^>]*>/)
      errors.add(:base, "nice try jackwagon")
    end
  end

  def clean_css
    return if custom_css.blank?

    self.custom_css = custom_css
      .gsub(/\/\*.*?<.*?\*\//m, "")
      .gsub(/<[^>]*>/, "")
      .strip
  end
end
