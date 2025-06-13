# frozen_string_literal: true

module Avo
  module Resources
    class User < Avo::BaseResource
      # self.includes = []
      # self.attachments = []
      # self.search = {
      #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
      # }

      def fields
        field :id, as: :id
        field :slack_id, as: :text
        field :email, as: :text
        field :first_name, as: :text
        field :middle_name, as: :text
        field :last_name, as: :text
        field :display_name, as: :text
        field :timezone, as: :text
        field :avatar, as: :text
        field :has_commented, as: :boolean
        field :has_hackatime, as: :boolean
        field :is_admin, as: :boolean
        field :projects, as: :has_many
        field :devlogs, as: :has_many
        field :votes, as: :has_many
        field :project_follows, as: :has_many
        field :followed_projects, as: :has_many, through: :project_follows
        field :timer_sessions, as: :has_many
        field :stonks, as: :has_many
        field :staked_projects, as: :has_many, through: :stonks
        field :hackatime_stat, as: :has_one
      end
    end
  end
end
