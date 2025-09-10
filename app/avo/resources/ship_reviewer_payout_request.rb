class Avo::Resources::ShipReviewerPayoutRequest < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :reviewer, as: :belongs_to
    field :amount, as: :number
    field :status, as: :number
    field :requested_at, as: :date_time
    field :approved_at, as: :date_time
    field :approved_by, as: :belongs_to
    field :decisions_count, as: :number
  end
end
